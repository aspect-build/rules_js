/**
 * An implementation of the aspect watch protocol for communicating with a host
 * such as aspect-cli.
 */
import * as net from 'node:net';
export var MessageType;
(function (MessageType) {
    MessageType["CYCLE"] = "CYCLE";
    MessageType["CYCLE_RESET"] = "CYCLE_RESET";
    MessageType["CYCLE_FAILED"] = "CYCLE_FAILED";
    MessageType["CYCLE_COMPLETED"] = "CYCLE_COMPLETED";
    MessageType["NEGOTIATE"] = "NEGOTIATE";
    MessageType["NEGOTIATE_RESPONSE"] = "NEGOTIATE_RESPONSE";
    MessageType["CAPS"] = "CAPS";
    MessageType["CAPS_RESPONSE"] = "CAPS_RESPONSE";
    MessageType["EXIT"] = "EXIT";
})(MessageType || (MessageType = {}));
// Environment constants
const { JS_BINARY__LOG_DEBUG } = process.env;
// The message framing delimiter byte.
const NEWLINE = '\n'.charCodeAt(0);
function selectVersion(versions) {
    if (versions.includes(3)) {
        return 3;
    }
    if (versions.includes(1)) {
        return 1;
    }
    if (versions.includes(0)) {
        return 0;
    }
    throw new Error(`No supported protocol versions: ${versions.join(', ')}`);
}
export class AspectWatchProtocol {
    constructor(socketFile) {
        this._version = -1;
        // Single persistent reader state: partial trailing line, parsed but
        // unconsumed messages, the pending _receive() and the terminal error.
        this._readTail = Buffer.alloc(0);
        this._received = [];
        this._receiver = null;
        this._terminated = null;
        this.socketFile = socketFile;
        this.connection = new net.Socket({});
        // Propagate connection errors to a configurable callback
        this._error = console.error;
        // A single persistent reader for the lifetime of the connection so
        // messages are framed correctly and never dropped between receives.
        this.connection.on('data', (data) => this._dataReceived(data));
        this.connection.on('error', (err) => this._terminate(err));
        this.connection.on('close', () => this._terminate(new Error('watch protocol connection closed')));
    }
    /**
     * Establish a connection to the Aspect Watcher server and complete the initial
     * handshake + negotiation.
     */
    async connect(requestedCaps = {}) {
        await new Promise((resolve, reject) => {
            // Initial connection + success vs failure
            this.connection.once('error', reject);
            try {
                this.connection.connect(this.socketFile, () => {
                    this.connection.off('error', reject);
                    resolve();
                });
            }
            catch (err) {
                this.connection.off('error', reject);
                reject(err);
            }
        });
        const { versions } = await this._receive(MessageType.NEGOTIATE);
        const version = selectVersion(versions);
        await this._send(MessageType.NEGOTIATE_RESPONSE, { version });
        this._version = version;
        if (version >= 1) {
            await this._send(MessageType.CAPS, {
                caps: requestedCaps,
            });
            const { caps: actualCaps } = await this._receive(MessageType.CAPS_RESPONSE);
            if (JS_BINARY__LOG_DEBUG) {
                console.log('AspectWatchProtocol[connect]: negotiated capabilities:', actualCaps);
            }
        }
        return this;
    }
    /**
     * Disconnect and close all connections from the Aspect Watcher server.
     */
    async disconnect() {
        if (this.connection.writable) {
            try {
                await this._send(MessageType.EXIT, {});
            }
            catch (e) {
                if (JS_BINARY__LOG_DEBUG) {
                    console.log('AspectWatchProtocol[disconnect]: failed to send EXIT message:', e);
                }
            }
            await new Promise((resolve) => this.connection.end(resolve));
            this.connection.destroy();
        }
        return this;
    }
    /**
     * @param callback Callback to be invoked on error.
     */
    onError(callback) {
        this._error = callback;
    }
    /**
     * @param callback Callback to be invoked on each cycle message.
     */
    onCycle(callback) {
        this._cycle = callback;
    }
    /**
     * Wait for the first cycle to complete. This is useful to ensure that the initial
     * build has completed before proceeding.
     */
    async awaitFirstCycle() {
        await this.cycle(true);
    }
    /**
     * Continue to listen for cycle messages and invoke the registered callback until
     * the connection is closed or an error occurs.
     */
    async cycle(once) {
        do {
            // Only receive cycle messages, forever up until the connection is closed.
            // Connection errors will propagate.
            const msg = await this._receive();
            // The server is shutting down; end the cycle loop cleanly.
            if (msg.kind === MessageType.EXIT) {
                return;
            }
            if (msg.kind !== MessageType.CYCLE &&
                msg.kind !== MessageType.CYCLE_RESET) {
                throw new Error(`Expected CYCLE or CYCLE_RESET, got ${msg.kind}`);
            }
            const cycleMsg = msg;
            // Invoke the cycle callback while recording+logging errors
            let cycleError = null;
            try {
                await this._cycle(cycleMsg);
            }
            catch (e) {
                this._error((cycleError = e));
            }
            // Respond with COMPLETE or FAILED for this cycle.
            // Connection errors will propagate.
            if (cycleError) {
                await this._send(MessageType.CYCLE_FAILED, {
                    cycle_id: cycleMsg.cycle_id,
                    description: cycleError.message,
                });
            }
            else {
                await this._send(MessageType.CYCLE_COMPLETED, {
                    cycle_id: cycleMsg.cycle_id,
                });
            }
        } while (!once && this.connection.readable && this.connection.writable);
    }
    // Split the byte stream into newline-delimited JSON messages, delivering
    // them to the pending _receive() or queueing them until one arrives.
    _dataReceived(data) {
        const buf = this._readTail.length
            ? Buffer.concat([this._readTail, data])
            : data;
        let start = 0;
        for (let nl = buf.indexOf(NEWLINE, start); nl !== -1; nl = buf.indexOf(NEWLINE, start)) {
            const line = buf.subarray(start, nl).toString().trim();
            start = nl + 1;
            if (!line) {
                continue;
            }
            let msg;
            try {
                msg = JSON.parse(line);
            }
            catch (e) {
                this._terminate(new Error(`Failed to parse watch protocol message: ${e}`));
                this.connection.destroy();
                return;
            }
            if (this._receiver) {
                const receiver = this._receiver;
                this._receiver = null;
                receiver.resolve(msg);
            }
            else {
                this._received.push(msg);
            }
        }
        // Copy the partial trailing line so the full chunk can be released.
        this._readTail =
            start < buf.length
                ? Buffer.from(buf.subarray(start))
                : Buffer.alloc(0);
    }
    // Fail the pending _receive() and all future receives, e.g. on socket error or close.
    _terminate(err) {
        if (this._terminated) {
            return;
        }
        this._terminated = err;
        if (this._receiver) {
            const receiver = this._receiver;
            this._receiver = null;
            receiver.reject(err);
        }
    }
    async _receive(type = null) {
        let msg;
        if (this._received.length > 0) {
            msg = this._received.shift();
        }
        else if (this._terminated) {
            throw this._terminated;
        }
        else if (this._receiver) {
            throw new Error('Concurrent _receive() calls are not supported');
        }
        else {
            msg = await new Promise((resolve, reject) => {
                this._receiver = { resolve, reject };
            });
        }
        if (type && msg.kind !== type) {
            throw new Error(`Expected message kind ${type}, got ${msg.kind}`);
        }
        return msg;
    }
    async _send(type, data) {
        await new Promise((resolve, reject) => {
            try {
                this.connection.write(JSON.stringify(Object.assign({ kind: type }, data)) + '\n', function (err) {
                    if (err) {
                        reject(err);
                    }
                    else {
                        resolve();
                    }
                });
            }
            catch (err) {
                reject(err);
            }
        });
    }
}
