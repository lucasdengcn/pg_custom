docker buildx build . -t localdev/pg-extensions:16

docker buildx build . --output type=tar,dest=./build_cache.tar

docker tag 045c24dfbe2a registry.cn-hangzhou.aliyuncs.com/ym01/pg-extensions:16

docker push registry.cn-hangzhou.aliyuncs.com/ym01/pg-extensions:16


docker buildx build . -t localdev/postgresql:16.1

image_id=$(docker image inspect --format '{{.Id}}' localdev/postgresql:16.1)

docker tag bcdff2c0095a registry.cn-hangzhou.aliyuncs.com/ym01/postgresql:16.1
docker push registry.cn-hangzhou.aliyuncs.com/ym01/postgresql:16.1
