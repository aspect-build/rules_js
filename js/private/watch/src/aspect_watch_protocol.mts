/**
 * An implementation of the aspect watch protocol for communicating with a host
 * such as aspect-cli.
 */

import * as net from 'node:net'

export enum MessageType {
    CYCLE = 'CYCLE',
    CYCLE_RESET = 'CYCLE_RESET',
    CYCLE_FAILED = 'CYCLE_FAILED',
    CYCLE_COMPLETED = 'CYCLE_COMPLETED',
    NEGOTIATE = 'NEGOTIATE',
    NEGOTIATE_RESPONSE = 'NEGOTIATE_RESPONSE',
    CAPS = 'CAPS',
    CAPS_RESPONSE = 'CAPS_RESPONSE',
    EXIT = 'EXIT',
}

export interface Message {
    readonly kind: MessageType

    // OTEL data may be present on any message if OTEL capabilities are available and negotiated.
    readonly trace_id?: string
    readonly span_id?: string
}

export interface NegotiateMessage extends Message {
    readonly kind: MessageType.NEGOTIATE
    readonly versions: number[]
}

export interface NegotiateResponseMessage extends Message {
    readonly kind: MessageType.NEGOTIATE_RESPONSE
    readonly version: number
}

export type WatchType = 'sources' | 'runfiles'

export interface Capabilities {
    scope: WatchType[]
    otel: boolean
}

export interface CapsMessage extends Message {
    readonly kind: MessageType.CAPS
    readonly caps: Partial<Capabilities>
}

export interface CapsResponseMessage extends Message {
    readonly kind: MessageType.CAPS_RESPONSE
    readonly caps: Capabilities
}

export interface SourceInfo {
    readonly is_symlink?: boolean
    readonly is_source?: boolean
}

export interface CycleMessageSources {
    readonly [key: string]: null | SourceInfo
}

export interface CycleMessage extends Message {
    readonly kind:
        | MessageType.CYCLE
        | MessageType.CYCLE_RESET
        | MessageType.CYCLE_FAILED
        | MessageType.CYCLE_COMPLETED
    readonly cycle_id: number
}

export interface CycleSourcesMessage extends CycleMessage {
    readonly kind: MessageType.CYCLE
    readonly sources: CycleMessageSources
}

export interface CycleResetMessage extends CycleMessage {
    readonly kind: MessageType.CYCLE_RESET
}

export interface CycleFailedMessage extends CycleMessage {
    readonly kind: MessageType.CYCLE_FAILED
    readonly description: string
}

export interface CycleCompletedMessage extends CycleMessage {
    readonly kind: MessageType.CYCLE_COMPLETED
}

export interface ExitMessage extends Message {
    readonly kind: MessageType.EXIT
}

// Environment constants
const { JS_BINARY__LOG_DEBUG } = process.env

// The message framing delimiter byte.
const NEWLINE = '\n'.charCodeAt(0)

function selectVersion(versions: number[]): number {
    if (versions.includes(3)) {
        return 3
    }
    if (versions.includes(1)) {
        return 1
    }
    if (versions.includes(0)) {
        return 0
    }

    throw new Error(`No supported protocol versions: ${versions.join(', ')}`)
}

export class AspectWatchProtocol {
    private readonly socketFile: string
    private readonly connection: net.Socket

    private _version: number = -1
    private _error: (err: Error) => void
    private _cycle: (msg: CycleMessage) => Promise<void>

    // Single persistent reader state: partial trailing line, parsed but
    // unconsumed messages, the pending _receive() and the terminal error.
    private _readTail: Buffer = Buffer.alloc(0)
    private _received: Message[] = []
    private _receiver: {
        resolve: (msg: Message) => void
        reject: (err: Error) => void
    } | null = null
    private _terminated: Error | null = null

    constructor(socketFile: string) {
        this.socketFile = socketFile
        this.connection = new net.Socket({})

        // Propagate connection errors to a configurable callback
        this._error = console.error

        // A single persistent reader for the lifetime of the connection so
        // messages are framed correctly and never dropped between receives.
        this.connection.on('data', (data) => this._dataReceived(data))
        this.connection.on('error', (err) => this._terminate(err))
        this.connection.on('close', () =>
            this._terminate(new Error('watch protocol connection closed'))
        )
    }

    /**
     * Establish a connection to the Aspect Watcher server and complete the initial
     * handshake + negotiation.
     */
    async connect(requestedCaps: Partial<Capabilities> = {}) {
        await new Promise<void>((resolve, reject) => {
            // Initial connection + success vs failure
            this.connection.once('error', reject)
            try {
                this.connection.connect(this.socketFile, () => {
                    this.connection.off('error', reject)
                    resolve()
                })
            } catch (err) {
                this.connection.off('error', reject)
                reject(err)
            }
        })

        const { versions } = await this._receive<NegotiateMessage>(
            MessageType.NEGOTIATE
        )

        const version = selectVersion(versions)

        await this._send<NegotiateResponseMessage>(
            MessageType.NEGOTIATE_RESPONSE,
            { version }
        )

        this._version = version

        if (version >= 1) {
            await this._send<CapsMessage>(MessageType.CAPS, {
                caps: requestedCaps,
            })

            const { caps: actualCaps } =
                await this._receive<CapsResponseMessage>(
                    MessageType.CAPS_RESPONSE
                )

            if (JS_BINARY__LOG_DEBUG) {
                console.log(
                    'AspectWatchProtocol[connect]: negotiated capabilities:',
                    actualCaps
                )
            }
        }

        return this
    }

    /**
     * Disconnect and close all connections from the Aspect Watcher server.
     */
    async disconnect() {
        if (this.connection.writable) {
            try {
                await this._send<ExitMessage>(MessageType.EXIT, {})
            } catch (e) {
                if (JS_BINARY__LOG_DEBUG) {
                    console.log(
                        'AspectWatchProtocol[disconnect]: failed to send EXIT message:',
                        e
                    )
                }
            }

            await new Promise<void>((resolve) => this.connection.end(resolve))

            this.connection.destroy()
        }

        return this
    }

    /**
     * @param callback Callback to be invoked on error.
     */
    onError(callback: (err: Error) => void) {
        this._error = callback
    }

    /**
     * @param callback Callback to be invoked on each cycle message.
     */
    onCycle(callback: (msg: CycleMessage) => Promise<void>) {
        this._cycle = callback
    }

    /**
     * Wait for the first cycle to complete. This is useful to ensure that the initial
     * build has completed before proceeding.
     */
    async awaitFirstCycle() {
        await this.cycle(true)
    }

    /**
     * Continue to listen for cycle messages and invoke the registered callback until
     * the connection is closed or an error occurs.
     */
    async cycle(once?: boolean) {
        do {
            // Only receive cycle messages, forever up until the connection is closed.
            // Connection errors will propagate.
            const msg = await this._receive<Message>()

            // The server is shutting down; end the cycle loop cleanly.
            if (msg.kind === MessageType.EXIT) {
                return
            }

            if (
                msg.kind !== MessageType.CYCLE &&
                msg.kind !== MessageType.CYCLE_RESET
            ) {
                throw new Error(
                    `Expected CYCLE or CYCLE_RESET, got ${msg.kind}`
                )
            }
            const cycleMsg = msg as CycleMessage

            // Invoke the cycle callback while recording+logging errors
            let cycleError = null
            try {
                await this._cycle(cycleMsg)
            } catch (e) {
                this._error((cycleError = e))
            }

            // Respond with COMPLETE or FAILED for this cycle.
            // Connection errors will propagate.
            if (cycleError) {
                await this._send<CycleFailedMessage>(MessageType.CYCLE_FAILED, {
                    cycle_id: cycleMsg.cycle_id,
                    description: cycleError.message,
                })
            } else {
                await this._send<CycleCompletedMessage>(
                    MessageType.CYCLE_COMPLETED,
                    {
                        cycle_id: cycleMsg.cycle_id,
                    }
                )
            }
        } while (!once && this.connection.readable && this.connection.writable)
    }

    // Split the byte stream into newline-delimited JSON messages, delivering
    // them to the pending _receive() or queueing them until one arrives.
    private _dataReceived(data: Buffer) {
        const buf = this._readTail.length
            ? Buffer.concat([this._readTail, data])
            : data

        let start = 0
        for (
            let nl = buf.indexOf(NEWLINE, start);
            nl !== -1;
            nl = buf.indexOf(NEWLINE, start)
        ) {
            const line = buf.subarray(start, nl).toString().trim()
            start = nl + 1
            if (!line) {
                continue
            }

            let msg: Message
            try {
                msg = JSON.parse(line)
            } catch (e) {
                this._terminate(
                    new Error(`Failed to parse watch protocol message: ${e}`)
                )
                this.connection.destroy()
                return
            }

            if (this._receiver) {
                const receiver = this._receiver
                this._receiver = null
                receiver.resolve(msg)
            } else {
                this._received.push(msg)
            }
        }

        // Copy the partial trailing line so the full chunk can be released.
        this._readTail =
            start < buf.length
                ? Buffer.from(buf.subarray(start))
                : Buffer.alloc(0)
    }

    // Fail the pending _receive() and all future receives, e.g. on socket error or close.
    private _terminate(err: Error) {
        if (this._terminated) {
            return
        }
        this._terminated = err

        if (this._receiver) {
            const receiver = this._receiver
            this._receiver = null
            receiver.reject(err)
        }
    }

    async _receive<M extends Message>(
        type: M['kind'] | null = null
    ): Promise<M> {
        let msg: Message
        if (this._received.length > 0) {
            msg = this._received.shift()
        } else if (this._terminated) {
            throw this._terminated
        } else if (this._receiver) {
            throw new Error('Concurrent _receive() calls are not supported')
        } else {
            msg = await new Promise<Message>((resolve, reject) => {
                this._receiver = { resolve, reject }
            })
        }

        if (type && msg.kind !== type) {
            throw new Error(`Expected message kind ${type}, got ${msg.kind}`)
        }
        return msg as M
    }

    async _send<M extends Message>(type: M['kind'], data: Omit<M, 'kind'>) {
        await new Promise<void>((resolve, reject) => {
            try {
                this.connection.write(
                    JSON.stringify({ kind: type, ...data }) + '\n',
                    function (err) {
                        if (err) {
                            reject(err)
                        } else {
                            resolve()
                        }
                    }
                )
            } catch (err) {
                reject(err)
            }
        })
    }
}
