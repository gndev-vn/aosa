namespace Aosa.Api.Middleware;

public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var method = context.Request.Method;
        var path = context.Request.Path + context.Request.QueryString;
        var origin = context.Request.Headers.Origin.ToString();
        var remoteIp = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        _logger.LogInformation("[REQ] {Method} {Path} from {Ip} Origin={Origin}", method, path, remoteIp, string.IsNullOrEmpty(origin) ? "none" : origin);

        await _next(context);

        var status = context.Response.StatusCode;
        _logger.LogInformation("[RES] {Method} {Path} -> {Status}", method, path, status);
    }
}
