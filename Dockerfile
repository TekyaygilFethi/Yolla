# Multi-arch build (amd64 + arm64, e.g. Raspberry Pi / ARM NAS) without emulating the compiler.
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG TARGETARCH
WORKDIR /src
COPY src/Yolla/Yolla.csproj .
RUN dotnet restore -a $TARGETARCH
COPY src/Yolla/ .
RUN dotnet publish Yolla.csproj -c Release -a $TARGETARCH --no-restore -o /app

# Alpine runtime: small image, and the app runs as an unprivileged user (uid 1000 by default;
# override with `user:` in compose / `--user` in docker run so it matches the owner of your folder).
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine
WORKDIR /app
COPY --from=build /app .
RUN mkdir -p /data && chown 1000:1000 /data
ENV UPLOAD_DIR=/data \
    ASPNETCORE_HTTP_PORTS=8080 \
    HOME=/tmp
USER 1000:1000
EXPOSE 8080
VOLUME ["/data"]
ENTRYPOINT ["dotnet", "Yolla.dll"]
