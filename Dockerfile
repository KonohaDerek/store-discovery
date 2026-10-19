FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /src
COPY global.json ./
COPY backend/StoreDiscovery.sln backend/
COPY backend/src/StoreDiscovery.Api/StoreDiscovery.Api.csproj backend/src/StoreDiscovery.Api/
COPY backend/tests/StoreDiscovery.Api.Tests/StoreDiscovery.Api.Tests.csproj backend/tests/StoreDiscovery.Api.Tests/
RUN dotnet restore backend/StoreDiscovery.sln

COPY backend/ backend/
RUN dotnet publish backend/src/StoreDiscovery.Api/StoreDiscovery.Api.csproj \
    --configuration Release \
    --output /app/publish \
    --no-restore \
    --no-self-contained

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime

WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "StoreDiscovery.Api.dll"]
