> **Note**: Local build is currently only supported on Linux OS distributions.

1. Download the source code or clone the repository;
2. Move to the build directory;

```bash
cd build
```

3. Edit the [build.yml](build.yml) file with your favorite tech stack version;
4. Match those version on the [docker compose](docker-compose.yml) file;
5. Build the images;

```bash
chmod +x build.sh ; ./build.sh
```

6. Build the cluster;

```bash
docker-compose up
```

7. Run Apache Spark code using the provided Jupyter [notebooks](workspace) with Scala, PySpark and SparkR examples;
8. Stop the cluster by typing `ctrl+c`.
