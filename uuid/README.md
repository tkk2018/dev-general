### The risk of UUIDv4 and UUIDv7

In short,

> Based on the results above, I conclude that as long as we generate at least 𝑔=2 UUIDs per second, the cutoff point will be at least 140737488355329 ms, which comes out to 4459.7 years. If we are generating several UUIDs per second then the cutoff point will be around 281474976710656 ms or 8919.4 years.
>
> In other words, if you are only focused on avoiding hash collisions then you should pretty much always choose v4 instead of v7. There can be other reasons for using UUID v7 though; for example, v7 will generate nearby UUIDs during each millisecond which can help with database index locality and thus improve runtime (see e.g. source). Overall, neither version is a strict upgrade over the other, and you just have to consider the tradeoffs when choosing a UUID algorithm for your specific application.
> [- source](https://math.stackexchange.com/a/4697317)
