docker buildx build . -t localdev/pg-extensions:16

docker buildx build . --output type=tar,dest=./build_cache.tar

docker tag 045c24dfbe2a registry.cn-hangzhou.aliyuncs.com/ym01/pg-extensions:16

docker push registry.cn-hangzhou.aliyuncs.com/ym01/pg-extensions:16