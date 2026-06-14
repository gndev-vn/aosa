using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;

namespace Aosa.Api.Middleware;

public static class RateLimitingExtensions
{
    public static IServiceCollection AddAosaRateLimiting(this IServiceCollection services)
    {
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            options.AddFixedWindowLimiter("Auth", auth =>
            {
                auth.PermitLimit = 10;
                auth.Window = TimeSpan.FromMinutes(1);
                auth.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
                auth.QueueLimit = 0;
            });

            options.AddFixedWindowLimiter("Api", api =>
            {
                api.PermitLimit = 120;
                api.Window = TimeSpan.FromMinutes(1);
                api.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
                api.QueueLimit = 0;
            });
        });

        return services;
    }
}
