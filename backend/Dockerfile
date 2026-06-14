FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY Aosa.slnx ./
COPY Aosa.Domain/Aosa.Domain.csproj Aosa.Domain/
COPY Aosa.Application/Aosa.Application.csproj Aosa.Application/
COPY Aosa.Infrastructure/Aosa.Infrastructure.csproj Aosa.Infrastructure/
COPY Aosa.Api/Aosa.Api.csproj Aosa.Api/

RUN dotnet restore Aosa.Api/Aosa.Api.csproj

COPY . .
RUN dotnet publish Aosa.Api/Aosa.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
EXPOSE 8080
EXPOSE 8081
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Aosa.Api.dll"]
