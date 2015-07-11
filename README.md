# Libzmq-ios

This is a script that downloads and builds libzmq for iOS, including libsodium support, including arm64 support.

Compile

Note: Make sure that you not have any space in path. Else these scripts will not work.

1. Download libzmq-ios as zip
2. Download libsodium-ios as zip
3. copy ./libsodium/ to ./libzmq-ios-master/libsodium-ios/
4. copy ./libsodium.sh to ./libzmq-ios-master/libsodium-ios/
5. run ./libzmq.sh
6. Wait until it's done
7. Should gives you ./libzmq_dist/include/*.h and lib/libzmq.a

At least it get's compiled.
