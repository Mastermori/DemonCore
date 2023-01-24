"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DemonassLanguageServerClient = void 0;
const fs = require("fs");
const cp = require("child_process");
const string_decoder_1 = require("string_decoder");
const vscode_1 = require("vscode");
const node_1 = require("vscode-languageclient/node");
const MIN_REQUIRED_PYTHON_VERSION = "3.9";
const DEFAULT_LSP_SERVER_HOST = "127.0.0.1";
const DEFAULT_LSP_SERVER_PORT = 8080;
function getConfigurationItem(name) {
    return vscode_1.workspace.getConfiguration().get(`demonass.${name}`) ?? null;
}
function ensure(messageIfTestFails, test, ...args) {
    if (!test(...args)) {
        throw new Error(messageIfTestFails);
    }
}
function ensureTrue(messageIfTestFails, test) {
    ensure(messageIfTestFails, () => test);
}
function execShell(command, options) {
    return new Promise((resolve, reject) => {
        cp.exec(command, options, (error, stdout, stderr) => {
            stdout = maybeConvertBufferToString(stdout);
            stderr = maybeConvertBufferToString(stderr);
            if (error) {
                reject({ error, stdout, stderr });
            }
            resolve({ stdout, stderr });
        });
    });
}
function maybeConvertBufferToString(arg, encoding = "utf-8") {
    if (Buffer.isBuffer(arg)) {
        return new string_decoder_1.StringDecoder(encoding).write(Buffer.from(arg));
    }
    return arg;
}
class DemonassLanguageServerClient {
    constructor() { }
    static makeLspClient() {
        if (!DemonassLanguageServerClient.instance) {
            DemonassLanguageServerClient.instance = new DemonassLanguageServerClient();
        }
        return DemonassLanguageServerClient.instance;
    }
    startLanguageServer(context) {
        this.ensureAacToolIsAvailable();
        this.ensureLspServerIsReady(context);
    }
    shutdownServer() {
        this.demonassLspClient.stop();
    }
    ensureAacToolIsAvailable() {
        const pythonPath = this.getConfigurationItemFile("pythonPath");
        this.ensureCorrectPythonVersionIsInstalled(pythonPath);
    }
    getConfigurationItemFile(name) {
        const item = getConfigurationItem(name);
        ensureTrue(`Cannot start Language Server; '${item}' is not configured!`, item.length > 0);
        ensureTrue(`Cannot use ${item} as it does not exist!`, fs.existsSync(item));
        return item;
    }
    async ensureCorrectPythonVersionIsInstalled(pythonPath) {
        const resolve = await execShell(`${pythonPath} --version`, {});
        ensureTrue(`Could not get the Python version.\n${resolve.stderr}`, !resolve.stderr);
        const pythonVersion = resolve.stdout.match(/\d+\.\d+\.\d+/)?.pop() ?? "unknown";
        ensureTrue(`The AaC tool requires Python ${MIN_REQUIRED_PYTHON_VERSION} or newer; current version is: ${pythonVersion}`, pythonVersion.startsWith(MIN_REQUIRED_PYTHON_VERSION));
    }
    ensureLspServerIsReady(context) {
        const serverPath = this.getConfigurationItemFile("serverPath");
        this.startLspClient(context, serverPath, getConfigurationItem("lspServerHost") ?? DEFAULT_LSP_SERVER_HOST, getConfigurationItem("lspServerPort") ?? DEFAULT_LSP_SERVER_PORT);
    }
    startLspClient(context, serverPath, host, port) {
        if (this.demonassLspClient) {
            return;
        }
        this.demonassLspClient = new node_1.LanguageClient("demonass", "DemonAssembler Language Client", this.getServerOptions(serverPath, "start-lsp", "--host", host, "--port", `${port}`), this.getClientOptions());
        this.demonassLspClient.trace = node_1.Trace.Verbose;
        context.subscriptions.push(this.demonassLspClient.start());
        this.registerHoverProvider(context);
    }
    async registerHoverProvider(context) {
        const client = this.demonassLspClient;
        context.subscriptions.push(vscode_1.languages.registerHoverProvider({ scheme: "file", language: "demonass", pattern: "**/*.dasmb" }, {
            provideHover(document, position, token) {
                vscode_1.window.showInformationMessage(`File: ${document.uri.path}; Line: ${position.line}; Character: ${position.character}`);
                return client.sendRequest("textDocument/hover", {
                    textDocument: document,
                    position: position,
                }, token);
            }
        }));
    }
    getServerOptions(command, ...args) {
        return {
            args,
            command,
        };
    }
    getClientOptions() {
        return {
            documentSelector: [
                { scheme: "file", language: "demonass", pattern: "**/*.dasmb" },
            ],
            diagnosticCollectionName: "demonass",
            outputChannelName: "Architecture-as-Code", //TODO: Find out what this does!
            // synchronize: {
            //     fileEvents: workspace.createFileSystemWatcher("**/.clientrc"),
            // }
        };
    }
}
exports.DemonassLanguageServerClient = DemonassLanguageServerClient;
//# sourceMappingURL=DemonassLanguageServer.js.map