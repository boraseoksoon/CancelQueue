## CancelQueue
'CancelQueue' performs the latest operation given time-constraint, throttling and ignoring the rest of continuous operations.


```swift
// Given continuous async inputs, latest one is only executed, cancelling all other async calls.
(0...1000).forEach { n in
    CancelQueue.global.async {
        print("=> \(n)")
    }
}

 => 10000


// style of how to execute async calls can be chosen for either prefix or suffix including order
// Leveraging DispatchQueue, you can choose block style either .sync or .async
(0...1000).forEach { n in
    CancelQueue.global.sync(.suffix(5), order:.desc) {
        print("=> \(n)")
    }
}

=> 1000
=> 999
=> 998
=> 997
=> 996


(0...10).forEach { n in
    CancelQueue.global.async(.prefix(5), order: .asc) {
        print("*\(n)*")
    }

    CancelQueue.main.async(.suffix(6), order: .asc) {
        print("@\(n)@")
    }
}

/*
 *0*
 *1*
 *2*
 *3*
 *4*
 @5@
 @6@
 @7@
 @8@
 @9@
 @10@
*/


```

## Installation
```

## Contributing

[Contributing Guide](Contributing.md)

## License

[MIT](LICENSE)
