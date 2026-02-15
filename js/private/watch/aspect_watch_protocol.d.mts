/**
 * An implementation of the aspect watch protocol for communicating with a host
 * such as aspect-cli.
 */
export declare enum MessageType {
    CYCLE = "CYCLE",
    CYCLE_FAILED = "CYCLE_FAILED",
    CYCLE_COMPLETED = "CYCLE_COMPLETED",
    NEGOTIATE = "NEGOTIATE",
    NEGOTIATE_RESPONSE = "NEGOTIATE_RESPONSE",
    CAPS = "CAPS",
    CAPS_RESPONSE = "CAPS_RESPONSE",
    EXIT = "EXIT"
}
export interface Message {
    readonly kind: MessageType;
    readonly traceId?: string;
    readonly spanId?: string;
}
export interface NegotiateMessage extends Message {
    readonly kind: MessageType.NEGOTIATE;
    readonly versions: number[];
}
export interface NegotiateResponseMessage extends Message {
    readonly kind: MessageType.NEGOTIATE_RESPONSE;
    readonly version: number;
}
export type WatchType = 'sources' | 'runfiles';
export interface Capabilities {
    scope: WatchType[];
    otel: boolean;
}
export interface CapsMessage extends Message {
    readonly kind: MessageType.CAPS;
    readonly caps: Partial<Capabilities>;
}
export interface CapsResponseMessage extends Message {
    readonly kind: MessageType.CAPS_RESPONSE;
    readonly caps: Capabilities;
}
export interface SourceInfo {
    readonly is_symlink?: boolean;
    readonly is_source?: boolean;
}
export interface CycleMessageSources {
    readonly [key: string]: null | SourceInfo;
}
export interface CycleMessage extends Message {
    readonly kind: MessageType.CYCLE | MessageType.CYCLE_FAILED | MessageType.CYCLE_COMPLETED;
    readonly cycle_id: number;
}
export interface CycleSourcesMessage extends CycleMessage {
    readonly kind: MessageType.CYCLE;
    readonly sources: CycleMessageSources;
}
export interface CycleFailedMessage extends CycleMessage {
    readonly kind: MessageType.CYCLE_FAILED;
    readonly description: string;
}
export interface CycleCompletedMessage extends CycleMessage {
    readonly kind: MessageType.CYCLE_COMPLETED;
}
export interface ExitMessage extends Message {
    readonly kind: MessageType.EXIT;
}
export declare class AspectWatchProtocol {
    private readonly socketFile;
    private readonly connection;
    private _version;
    private _error;
    private _cycle;
    constructor(socketFile: string);
    /**
     * Establish a connection to the Aspect Watcher server and complete the initial
     * handshake + negotiation.
     */
    connect(requestedCaps?: Partial<Capabilities>): Promise<this>;
    /**
     * Disconnect and close all connections from the Aspect Watcher server.
     */
    disconnect(): Promise<this>;
    /**
     * @param callback Callback to be invoked on error.
     */
    onError(callback: (err: Error) => void): void;
    /**
     * @param callback Callback to be invoked on each cycle message.
     */
    onCycle(callback: (msg: CycleMessage) => Promise<void>): void;
    /**
     * Wait for the first cycle to complete. This is useful to ensure that the initial
     * build has completed before proceeding.
     */
    awaitFirstCycle(): Promise<void>;
    /**
     * Continue to listen for cycle messages and invoke the registered callback until
     * the connection is closed or an error occurs.
     */
    cycle(once?: boolean): Promise<void>;
    _receive<M extends Message>(type?: M['kind'] | null): Promise<M>;
    _send<M extends Message>(type: M['kind'], data: Omit<M, 'kind'>): Promise<void>;
}
