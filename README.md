```
git clone <this repo> && cd <this repo>
docker build -t pavlov .
docker run -d -p 7777:7777/udp -p 8177:8177/udp --name=pavlov pavlov
```
