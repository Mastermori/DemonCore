"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const path = require("path");
const net = require("net");
const vscode_1 = require("vscode");
const node_1 = require("vscode-languageclient/node");
let client;
function startLangServerTCP(addr) {
    const serverOptions = () => {
        return new Promise((resolve /*, reject */) => {
            const clientSocket = new net.Socket();
            clientSocket.connect(addr, "127.0.0.1", () => {
                resolve({
                    reader: clientSocket,
                    writer: clientSocket,
                });
            });
        });
    };
    return new node_1.LanguageClient(`tcp lang server (port ${addr})`, serverOptions, getClientOptions());
}
function getClientOptions() {
    return {
        // Register the server for plain text documents
        documentSelector: [
            { scheme: "file", language: "demonass" },
            { scheme: "untitled", language: "demonass" },
        ],
        outputChannelName: "[pygls] DemonassLanguageServer",
        synchronize: {
            // Notify the server about file changes to '.clientrc files contain in the workspace
            fileEvents: vscode_1.workspace.createFileSystemWatcher("**/.clientrc"),
        },
    };
}
function startLangServer(command, args, cwd) {
    const serverOptions = {
        args,
        command,
        options: { cwd },
    };
    return new node_1.LanguageClient(command, serverOptions, getClientOptions());
}
// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
function activate(context) {
    if (context.extensionMode === vscode_1.ExtensionMode.Development) {
        // Development - Run the server manually
        client = startLangServerTCP(8080);
    }
    else {
        // Production - Client is going to run the server (for use within `.vsix` package)
        const cwd = path.join(__dirname, "..", "..");
        const pythonPath = vscode_1.workspace
            .getConfiguration("demonass")
            .get("pythonPath");
        if (!pythonPath) {
            throw new Error("`demonass.pythonPath` is not set");
        }
        client = startLangServer(pythonPath, ["-m", "server"], cwd);
    }
    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log('Congratulations, your extension "demonass" is now active!');
    // // The command has been defined in the package.json file
    // // Now provide the implementation of the command with registerCommand
    // // The commandId parameter must match the command field in package.json
    // let disposable = commands.registerCommand('demonass.helloWorld', () => {
    // 	// The code you place here will be executed every time your command is executed
    // 	// Display a message box to the user
    // 	window.showInformationMessage('Hello VS Code from DemonAssembler!');
    // });
    context.subscriptions.push(client.start());
}
exports.activate = activate;
// This method is called when your extension is deactivated
function deactivate() {
    return client ? client.stop() : Promise.resolve();
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map