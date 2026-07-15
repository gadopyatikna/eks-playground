# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/ClientWebApi/ClientWebApi.csproj src/ClientWebApi/
RUN dotnet restore src/ClientWebApi/ClientWebApi.csproj

COPY src/ClientWebApi/ src/ClientWebApi/
RUN dotnet publish src/ClientWebApi/ClientWebApi.csproj --configuration Release --no-restore --output /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:8080 \
    DOTNET_EnableDiagnostics=0

COPY --from=build /app/publish .

USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "ClientWebApi.dll"]
