/**
 * Generated by the protoc-gen-ts.  DO NOT EDIT!
 * compiler version: 3.19.3
 * source: worker_protocol.proto
 * git: https://github.com/thesayyn/protoc-gen-ts */
 import * as pb_1 from "google-protobuf";
 export namespace blaze.worker {
     export class Input extends pb_1.Message {
         #one_of_decls: number[][] = [];
         constructor(data?: any[] | {
             path?: string;
             digest?: Uint8Array;
         }) {
             super();
             pb_1.Message.initialize(this, Array.isArray(data) ? data : [], 0, -1, [], this.#one_of_decls);
             if (!Array.isArray(data) && typeof data == "object") {
                 if ("path" in data && data.path != undefined) {
                     this.path = data.path;
                 }
                 if ("digest" in data && data.digest != undefined) {
                     this.digest = data.digest;
                 }
             }
         }
         get path() {
             return pb_1.Message.getFieldWithDefault(this, 1, "") as string;
         }
         set path(value: string) {
             pb_1.Message.setField(this, 1, value);
         }
         get digest() {
             return pb_1.Message.getFieldWithDefault(this, 2, new Uint8Array(0)) as Uint8Array;
         }
         set digest(value: Uint8Array) {
             pb_1.Message.setField(this, 2, value);
         }
         static fromObject(data: {
             path?: string;
             digest?: Uint8Array;
         }): Input {
             const message = new Input({});
             if (data.path != null) {
                 message.path = data.path;
             }
             if (data.digest != null) {
                 message.digest = data.digest;
             }
             return message;
         }
         toObject() {
             const data: {
                 path?: string;
                 digest?: Uint8Array;
             } = {};
             if (this.path != null) {
                 data.path = this.path;
             }
             if (this.digest != null) {
                 data.digest = this.digest;
             }
             return data;
         }
         serialize(): Uint8Array;
         serialize(w: pb_1.BinaryWriter): void;
         serialize(w?: pb_1.BinaryWriter): Uint8Array | void {
             const writer = w || new pb_1.BinaryWriter();
             if (this.path.length)
                 writer.writeString(1, this.path);
             if (this.digest.length)
                 writer.writeBytes(2, this.digest);
             if (!w)
                 return writer.getResultBuffer();
         }
         static deserialize(bytes: Uint8Array | pb_1.BinaryReader): Input {
             const reader = bytes instanceof pb_1.BinaryReader ? bytes : new pb_1.BinaryReader(bytes), message = new Input();
             while (reader.nextField()) {
                 if (reader.isEndGroup())
                     break;
                 switch (reader.getFieldNumber()) {
                     case 1:
                         message.path = reader.readString();
                         break;
                     case 2:
                         message.digest = reader.readBytes();
                         break;
                     default: reader.skipField();
                 }
             }
             return message;
         }
         serializeBinary(): Uint8Array {
             return this.serialize();
         }
         static deserializeBinary(bytes: Uint8Array): Input {
             return Input.deserialize(bytes);
         }
     }
     export class WorkRequest extends pb_1.Message {
         #one_of_decls: number[][] = [];
         constructor(data?: any[] | {
             arguments?: string[];
             inputs?: Input[];
             request_id?: number;
             cancel?: boolean;
             verbosity?: number;
             sandbox_dir?: string;
         }) {
             super();
             pb_1.Message.initialize(this, Array.isArray(data) ? data : [], 0, -1, [1, 2], this.#one_of_decls);
             if (!Array.isArray(data) && typeof data == "object") {
                 if ("arguments" in data && data.arguments != undefined) {
                     this.arguments = data.arguments;
                 }
                 if ("inputs" in data && data.inputs != undefined) {
                     this.inputs = data.inputs;
                 }
                 if ("request_id" in data && data.request_id != undefined) {
                     this.request_id = data.request_id;
                 }
                 if ("cancel" in data && data.cancel != undefined) {
                     this.cancel = data.cancel;
                 }
                 if ("verbosity" in data && data.verbosity != undefined) {
                     this.verbosity = data.verbosity;
                 }
                 if ("sandbox_dir" in data && data.sandbox_dir != undefined) {
                     this.sandbox_dir = data.sandbox_dir;
                 }
             }
         }
         get arguments() {
             return pb_1.Message.getFieldWithDefault(this, 1, []) as string[];
         }
         set arguments(value: string[]) {
             pb_1.Message.setField(this, 1, value);
         }
         get inputs() {
             return pb_1.Message.getRepeatedWrapperField(this, Input, 2) as Input[];
         }
         set inputs(value: Input[]) {
             pb_1.Message.setRepeatedWrapperField(this, 2, value);
         }
         get request_id() {
             return pb_1.Message.getFieldWithDefault(this, 3, 0) as number;
         }
         set request_id(value: number) {
             pb_1.Message.setField(this, 3, value);
         }
         get cancel() {
             return pb_1.Message.getFieldWithDefault(this, 4, false) as boolean;
         }
         set cancel(value: boolean) {
             pb_1.Message.setField(this, 4, value);
         }
         get verbosity() {
             return pb_1.Message.getFieldWithDefault(this, 5, 0) as number;
         }
         set verbosity(value: number) {
             pb_1.Message.setField(this, 5, value);
         }
         get sandbox_dir() {
             return pb_1.Message.getFieldWithDefault(this, 6, "") as string;
         }
         set sandbox_dir(value: string) {
             pb_1.Message.setField(this, 6, value);
         }
         static fromObject(data: {
             arguments?: string[];
             inputs?: ReturnType<typeof Input.prototype.toObject>[];
             request_id?: number;
             cancel?: boolean;
             verbosity?: number;
             sandbox_dir?: string;
         }): WorkRequest {
             const message = new WorkRequest({});
             if (data.arguments != null) {
                 message.arguments = data.arguments;
             }
             if (data.inputs != null) {
                 message.inputs = data.inputs.map(item => Input.fromObject(item));
             }
             if (data.request_id != null) {
                 message.request_id = data.request_id;
             }
             if (data.cancel != null) {
                 message.cancel = data.cancel;
             }
             if (data.verbosity != null) {
                 message.verbosity = data.verbosity;
             }
             if (data.sandbox_dir != null) {
                 message.sandbox_dir = data.sandbox_dir;
             }
             return message;
         }
         toObject() {
             const data: {
                 arguments?: string[];
                 inputs?: ReturnType<typeof Input.prototype.toObject>[];
                 request_id?: number;
                 cancel?: boolean;
                 verbosity?: number;
                 sandbox_dir?: string;
             } = {};
             if (this.arguments != null) {
                 data.arguments = this.arguments;
             }
             if (this.inputs != null) {
                 data.inputs = this.inputs.map((item: Input) => item.toObject());
             }
             if (this.request_id != null) {
                 data.request_id = this.request_id;
             }
             if (this.cancel != null) {
                 data.cancel = this.cancel;
             }
             if (this.verbosity != null) {
                 data.verbosity = this.verbosity;
             }
             if (this.sandbox_dir != null) {
                 data.sandbox_dir = this.sandbox_dir;
             }
             return data;
         }
         serialize(): Uint8Array;
         serialize(w: pb_1.BinaryWriter): void;
         serialize(w?: pb_1.BinaryWriter): Uint8Array | void {
             const writer = w || new pb_1.BinaryWriter();
             if (this.arguments.length)
                 writer.writeRepeatedString(1, this.arguments);
             if (this.inputs.length)
                 writer.writeRepeatedMessage(2, this.inputs, (item: Input) => item.serialize(writer));
             if (this.request_id != 0)
                 writer.writeInt32(3, this.request_id);
             if (this.cancel != false)
                 writer.writeBool(4, this.cancel);
             if (this.verbosity != 0)
                 writer.writeInt32(5, this.verbosity);
             if (this.sandbox_dir.length)
                 writer.writeString(6, this.sandbox_dir);
             if (!w)
                 return writer.getResultBuffer();
         }
         static deserialize(bytes: Uint8Array | pb_1.BinaryReader): WorkRequest {
             const reader = bytes instanceof pb_1.BinaryReader ? bytes : new pb_1.BinaryReader(bytes), message = new WorkRequest();
             while (reader.nextField()) {
                 if (reader.isEndGroup())
                     break;
                 switch (reader.getFieldNumber()) {
                     case 1:
                         pb_1.Message.addToRepeatedField(message, 1, reader.readString());
                         break;
                     case 2:
                         reader.readMessage(message.inputs, () => pb_1.Message.addToRepeatedWrapperField(message, 2, Input.deserialize(reader), Input));
                         break;
                     case 3:
                         message.request_id = reader.readInt32();
                         break;
                     case 4:
                         message.cancel = reader.readBool();
                         break;
                     case 5:
                         message.verbosity = reader.readInt32();
                         break;
                     case 6:
                         message.sandbox_dir = reader.readString();
                         break;
                     default: reader.skipField();
                 }
             }
             return message;
         }
         serializeBinary(): Uint8Array {
             return this.serialize();
         }
         static deserializeBinary(bytes: Uint8Array): WorkRequest {
             return WorkRequest.deserialize(bytes);
         }
     }
     export class WorkResponse extends pb_1.Message {
         #one_of_decls: number[][] = [];
         constructor(data?: any[] | {
             exit_code?: number;
             output?: string;
             request_id?: number;
             was_cancelled?: boolean;
         }) {
             super();
             pb_1.Message.initialize(this, Array.isArray(data) ? data : [], 0, -1, [], this.#one_of_decls);
             if (!Array.isArray(data) && typeof data == "object") {
                 if ("exit_code" in data && data.exit_code != undefined) {
                     this.exit_code = data.exit_code;
                 }
                 if ("output" in data && data.output != undefined) {
                     this.output = data.output;
                 }
                 if ("request_id" in data && data.request_id != undefined) {
                     this.request_id = data.request_id;
                 }
                 if ("was_cancelled" in data && data.was_cancelled != undefined) {
                     this.was_cancelled = data.was_cancelled;
                 }
             }
         }
         get exit_code() {
             return pb_1.Message.getFieldWithDefault(this, 1, 0) as number;
         }
         set exit_code(value: number) {
             pb_1.Message.setField(this, 1, value);
         }
         get output() {
             return pb_1.Message.getFieldWithDefault(this, 2, "") as string;
         }
         set output(value: string) {
             pb_1.Message.setField(this, 2, value);
         }
         get request_id() {
             return pb_1.Message.getFieldWithDefault(this, 3, 0) as number;
         }
         set request_id(value: number) {
             pb_1.Message.setField(this, 3, value);
         }
         get was_cancelled() {
             return pb_1.Message.getFieldWithDefault(this, 4, false) as boolean;
         }
         set was_cancelled(value: boolean) {
             pb_1.Message.setField(this, 4, value);
         }
         static fromObject(data: {
             exit_code?: number;
             output?: string;
             request_id?: number;
             was_cancelled?: boolean;
         }): WorkResponse {
             const message = new WorkResponse({});
             if (data.exit_code != null) {
                 message.exit_code = data.exit_code;
             }
             if (data.output != null) {
                 message.output = data.output;
             }
             if (data.request_id != null) {
                 message.request_id = data.request_id;
             }
             if (data.was_cancelled != null) {
                 message.was_cancelled = data.was_cancelled;
             }
             return message;
         }
         toObject() {
             const data: {
                 exit_code?: number;
                 output?: string;
                 request_id?: number;
                 was_cancelled?: boolean;
             } = {};
             if (this.exit_code != null) {
                 data.exit_code = this.exit_code;
             }
             if (this.output != null) {
                 data.output = this.output;
             }
             if (this.request_id != null) {
                 data.request_id = this.request_id;
             }
             if (this.was_cancelled != null) {
                 data.was_cancelled = this.was_cancelled;
             }
             return data;
         }
         serialize(): Uint8Array;
         serialize(w: pb_1.BinaryWriter): void;
         serialize(w?: pb_1.BinaryWriter): Uint8Array | void {
             const writer = w || new pb_1.BinaryWriter();
             if (this.exit_code != 0)
                 writer.writeInt32(1, this.exit_code);
             if (this.output.length)
                 writer.writeString(2, this.output);
             if (this.request_id != 0)
                 writer.writeInt32(3, this.request_id);
             if (this.was_cancelled != false)
                 writer.writeBool(4, this.was_cancelled);
             if (!w)
                 return writer.getResultBuffer();
         }
         static deserialize(bytes: Uint8Array | pb_1.BinaryReader): WorkResponse {
             const reader = bytes instanceof pb_1.BinaryReader ? bytes : new pb_1.BinaryReader(bytes), message = new WorkResponse();
             while (reader.nextField()) {
                 if (reader.isEndGroup())
                     break;
                 switch (reader.getFieldNumber()) {
                     case 1:
                         message.exit_code = reader.readInt32();
                         break;
                     case 2:
                         message.output = reader.readString();
                         break;
                     case 3:
                         message.request_id = reader.readInt32();
                         break;
                     case 4:
                         message.was_cancelled = reader.readBool();
                         break;
                     default: reader.skipField();
                 }
             }
             return message;
         }
         serializeBinary(): Uint8Array {
             return this.serialize();
         }
         static deserializeBinary(bytes: Uint8Array): WorkResponse {
             return WorkResponse.deserialize(bytes);
         }
     }
 }
 