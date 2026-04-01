/**
 * An implementation of the aspect watch protocol for communicating with a host
 * such as aspect-cli.
 */
import * as net from 'node:net';
export var MessageType;
(function (MessageType) {
    MessageType["CYCLE"] = "CYCLE";
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
function selectVersion(versions) {
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
        this.socketFile = socketFile;
        this.connection = new net.Socket({});
        // Propagate connection errors to a configurable callback
        this._error = console.error;
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
                this.connection.connect(this.socketFile, resolve);
            }
            catch (err) {
                reject(err);
            }
            finally {
                this.connection.off('error', reject);
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
            // Only receive a cycle messages, forever up until the connection is closed.
            // Connection errors will propagate.
            const cycleMsg = await this._receive(MessageType.CYCLE);
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
    async _receive(type = null) {
        return await new Promise((resolve, reject) => {
            const dataBufs = [];
            const connection = this.connection;
            connection.once('error', onError);
            connection.once('close', onError);
            connection.on('data', dataReceived);
            // Destructor removing all temporary event handlers.
            function removeHandlers() {
                connection.off('error', onError);
                connection.off('close', onError);
                connection.off('data', dataReceived);
            }
            // Error event handler
            function onError(err) {
                removeHandlers();
                reject(err);
            }
            // Data event handler to receive data and determine when to resolve the promise.
            function dataReceived(data) {
                dataBufs.push(data);
                if (data.at(data.byteLength - 1) !== '\n'.charCodeAt(0)) {
                    return;
                }
                // Removal all temporary event handlers before resolving the promise
                removeHandlers();
                try {
                    const msg = JSON.parse(Buffer.concat(dataBufs).toString().trim());
                    if (type && msg.kind !== type) {
                        reject(new Error(`Expected message kind ${type}, got ${msg.kind}`));
                    }
                    else {
                        resolve(msg);
                    }
                }
                catch (e) {
                    reject(e);
                }
            }
        });
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
