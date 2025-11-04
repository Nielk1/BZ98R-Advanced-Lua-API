using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.FileProviders;
using System.Text.RegularExpressions;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Get log file path from command line, default to "log.txt"
var logFilePath = args.Length > 0 ? args[0] : "log.txt";

// Serve static HTML
app.UseDefaultFiles();
app.UseStaticFiles();

//app.MapGet("/", () => "Hello World!");

// Chunked log tail endpoint
app.MapGet("/tail", async (HttpContext context) =>
{
    context.Response.Headers.Append("Content-Type", "text/event-stream");
    using var fs = new FileStream(logFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
    using var reader = new StreamReader(fs);

    // Seek to end of file
    //fs.Seek(0, SeekOrigin.End);

    var printRegex = new Regex(@"\|LUA\|PRINT\|(.*?)\|PRINT\|LUA\|");
    var errorRegex = new Regex(@"\|LUA\|ERROR\|(.*?)\|ERROR\|LUA\|");

    long lastPosition = fs.Position;

    while (!context.RequestAborted.IsCancellationRequested)
    {
        // Detect file reset/truncate
        if (fs.Length < lastPosition)
        {
            // File was truncated/reset
            await context.Response.WriteAsync("data: reset|Log file reset\n\n");
            await context.Response.Body.FlushAsync();

            fs.Seek(0, SeekOrigin.Begin);
            reader.DiscardBufferedData(); // Reset StreamReader buffer
            lastPosition = 0;
        }

        var line = await reader.ReadLineAsync();
        if (line != null)
        {
            lastPosition = fs.Position;
            string? msg = null;
            string? type = null;
            if (printRegex.IsMatch(line))
            {
                msg = printRegex.Match(line).Groups[1].Value;
                type = "print";
            }
            else if (errorRegex.IsMatch(line))
            {
                msg = errorRegex.Match(line).Groups[1].Value;
                type = "error";
            }

            if (msg != null)
            {
                await context.Response.WriteAsync($"data: {type}|{msg}\n\n");
                await context.Response.Body.FlushAsync();
            }
        }
        else
        {
            await Task.Delay(500);
        }
    }
});

app.Run();