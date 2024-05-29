Check the `BleManager`. Originally, the `Request` doesn't extend the `Operation`. Unfortunately, I have not saved before I changed it.

Basically, no need to type cast to execute type specific function. They are move to the their own classes. Make the `execute` of BleManager more cleaner.

The `onError` and `onSuccess` may not neccessary. The `onError` remove the type case in the `handleError` of `BleManager`, but this require the `Error` type to be a common one, if not, type cast will still required.
