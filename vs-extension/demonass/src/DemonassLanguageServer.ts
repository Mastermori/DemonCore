import * as fs from "fs";
import * as cp from 'child_process';
import { StringDecoder } from "string_decoder";
import { ExtensionContext, Hover, HoverProvider, languages, ProviderResult, window, workspace } from "vscode";
import { LanguageClient, LanguageClientOptions, ServerOptions, Trace } from "vscode-languageclient/node";


const MIN_REQUIRED_PYTHON_VERSION = "3.9";
const DEFAULT_LSP_SERVER_HOST = "127.0.0.1";
const DEFAULT_LSP_SERVER_PORT = 8080;

function getConfigurationItem(name: string): any {
    return workspace.getConfiguration().get(`demonass.${name}`) ?? null;
}

function ensure(messageIfTestFails: string, test: (...args: any[]) => boolean, ...args: any[]): void {
    if (!test(...args)) {
        throw new Error(messageIfTestFails);
    }
}

function ensureTrue(messageIfTestFails: string, test: boolean): void {
    ensure(messageIfTestFails, () => test);
}

function execShell(command: string, options?: cp.ExecOptions): Promise<{ stdout: string; stderr: string }> {
    return new Promise<{ stdout: string; stderr: string }>((resolve, reject) => {
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

function maybeConvertBufferToString(arg: string | Buffer, encoding: BufferEncoding = "utf-8"): string {
    if (Buffer.isBuffer(arg)) {
        return new StringDecoder(encoding).write(Buffer.from(arg));
    }
    return <string>arg;
}

export class DemonassLanguageServerClient {
    private static instance: DemonassLanguageServerClient;

    private demonassLspClient!: LanguageClient;

    private constructor() { }

    public static makeLspClient(): DemonassLanguageServerClient {
        if (!DemonassLanguageServerClient.instance) {
            DemonassLanguageServerClient.instance = new DemonassLanguageServerClient();
        }
        return DemonassLanguageServerClient.instance;
    }

    public startLanguageServer(context: ExtensionContext): void {
        this.ensureAacToolIsAvailable();
        this.ensureLspServerIsReady(context);
    }

    public shutdownServer(): void {
        this.demonassLspClient.stop();
    }

    private ensureAacToolIsAvailable(): void {
        const pythonPath = this.getConfigurationItemFile("pythonPath");
        this.ensureCorrectPythonVersionIsInstalled(pythonPath);
    }

    private getConfigurationItemFile(name: string): string {
        const item: string = getConfigurationItem(name);
        ensureTrue(`Cannot start Language Server; '${item}' is not configured!`, item.length > 0);
        ensureTrue(`Cannot use ${item} as it does not exist!`, fs.existsSync(item));
        return item;
    }

    private async ensureCorrectPythonVersionIsInstalled(pythonPath: string): Promise<void> {
        const resolve = await execShell(`${pythonPath} --version`, {});
        ensureTrue(`Could not get the Python version.\n${resolve.stderr}`, !resolve.stderr);

        const pythonVersion = resolve.stdout.match(/\d+\.\d+\.\d+/)?.pop() ?? "unknown";
        ensureTrue(
            `The AaC tool requires Python ${MIN_REQUIRED_PYTHON_VERSION} or newer; current version is: ${pythonVersion}`,
            pythonVersion.startsWith(MIN_REQUIRED_PYTHON_VERSION)
        );
    }

    private ensureLspServerIsReady(context: ExtensionContext): void {
        const serverPath: string = this.getConfigurationItemFile("serverPath");
        this.startLspClient(
            context,
            serverPath,
            getConfigurationItem("lspServerHost") ?? DEFAULT_LSP_SERVER_HOST,
            getConfigurationItem("lspServerPort") ?? DEFAULT_LSP_SERVER_PORT,
        );
    }

    private startLspClient(context: ExtensionContext, serverPath: string, host: string, port: number): void {
        if (this.demonassLspClient) { return; }
        this.demonassLspClient = new LanguageClient(
            "demonass",
            "DemonAssembler Language Client",
            this.getServerOptions(serverPath, "start-lsp", "--host", host, "--port", `${port}`),
            this.getClientOptions(),
        );
        this.demonassLspClient.trace = Trace.Verbose;
        context.subscriptions.push(this.demonassLspClient.start());
        this.registerHoverProvider(context);
    }

    private async registerHoverProvider(context: ExtensionContext): Promise<void> {
        const client = this.demonassLspClient;
        context.subscriptions.push(languages.registerHoverProvider({ scheme: "file", language: "demonass", pattern: "**/*.dasmb" }, {
            provideHover(document, position, token): ProviderResult<Hover> {
                window.showInformationMessage(
                    `File: ${document.uri.path}; Line: ${position.line}; Character: ${position.character}`
                );
                return client.sendRequest("textDocument/hover", {
                    textDocument: document,
                    position: position,
                }, token);
            }
        }));
    }

    private getServerOptions(command: string, ...args: any[]): ServerOptions {
        return {
            args,
            command,
        };
    }

    private getClientOptions(): LanguageClientOptions {
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