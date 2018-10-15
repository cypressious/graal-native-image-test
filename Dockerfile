FROM gradle:4.10.2-jdk8-alpine as builder
WORKDIR /app

COPY build.gradle .
COPY settings.gradle .

# Cache dependencies
USER root
RUN chown -R gradle /app
USER gradle

RUN gradle --no-daemon resolveDependencies

# Compile
COPY src src

USER root
RUN chown -R gradle /app
USER gradle

RUN gradle --no-daemon fatJar

FROM findepi/graalvm:1.0.0-rc7-native as graal
WORKDIR /app

COPY --from=builder /app/build/libs/ .

RUN native-image -jar native-image-test-all-1.0-SNAPSHOT.jar\
 -H:+JNI \
 -H:+ReportUnsupportedElementsAtRuntime \
 -H:Name=native-image-test\
 --static\
 --enable-all-security-services\
 --enable-https\
 --no-server


FROM scratch
COPY --from=graal /app/native-image-test /

ENTRYPOINT ["/native-image-test"]