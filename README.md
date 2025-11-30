# MessagePack for ColdFusion 2016+

A pure ColdFusion port of [msgpack-lite](https://github.com/kawanet/msgpack-lite) for encoding and decoding MessagePack binary format. Compatible with ColdFusion 2016+ and Java 11+.

## Features

- ✅ Pure CFScript implementation (no external dependencies)
- ✅ Full MessagePack specification support
- ✅ Compatible with msgpack-lite and other MessagePack implementations
- ✅ Handles all MessagePack data types (nil, boolean, integer, float, string, binary, array, map)
- ✅ Efficient binary encoding/decoding using Java NIO
- ✅ Support for nested structures
- ✅ Unicode string support (UTF-8)
- ✅ Binary data support

## Requirements

- ColdFusion 2016 or higher (tested on CF2016, CF2018, CF2021), Lucee 6 and BoxLang.
- Java 11 or higher
- No external library dependencies

## Installation

1. Copy `MessagePack.cfc` to your ColdFusion application directory
2. Instantiate the component in your code

```cfml
<cfscript>
msgpack = new MessagePack();
</cfscript>
```

## Basic Usage

### Encoding (ColdFusion → MessagePack)

```cfml
<cfscript>
msgpack = new MessagePack();

// Encode a struct to binary
data = {foo: "bar", num: 123, active: true};
encoded = msgpack.encode(data);

// Encode to hex string (useful for debugging or text-based transmission)
hexEncoded = msgpack.encode(data, true);
// Returns: "83A3666F6FA3626172A36E756D7BA6616374697665C3"
</cfscript>
```

### Decoding (MessagePack → ColdFusion)

```cfml
<cfscript>
msgpack = new MessagePack();

// Decode from binary
decoded = msgpack.decode(encoded);

// Decode from hex string
hexDecoded = msgpack.decode("83A3666F6FA3626172A36E756D7B", true);

// Hex strings can include spaces, colons, or hyphens for readability
hexDecoded = msgpack.decode("83 A3 66 6F 6F A3 62 61 72", true);
hexDecoded = msgpack.decode("83:A3:66:6F:6F:A3:62:61:72", true);
hexDecoded = msgpack.decode("83-A3-66-6F-6F-A3-62-61-72", true);

// All decode to: {foo: "bar", num: 123}
writeDump(decoded);
</cfscript>
```

## API Reference

### encode(value, asHex)

Encodes a ColdFusion value to MessagePack format.

**Parameters:**
- `value` (required): The value to encode (struct, array, string, number, boolean, null)
- `asHex` (optional, default: false): Return as hex string instead of binary

**Returns:**
- Binary byte array (default)
- Hex string (if asHex=true)

**Examples:**
```cfscript
// Binary output
binary = msgpack.encode({foo: "bar"});

// Hex string output
hex = msgpack.encode({foo: "bar"}, true);
// Returns: "81A3666F6FA3626172"
```

### decode(data, isHex)

Decodes MessagePack data to a ColdFusion value.

**Parameters:**
- `data` (required): Binary data, byte array, or hex string
- `isHex` (optional, default: false): Indicates if data is a hex string

**Returns:**
- Decoded ColdFusion value (struct, array, string, number, boolean, or null)

**Examples:**
```cfscript
// Decode binary
decoded = msgpack.decode(binaryData);

// Decode hex string
decoded = msgpack.decode("81A3666F6FA3626172", true);

// Decode formatted hex string (spaces ignored)
decoded = msgpack.decode("81 A3 66 6F 6F A3 62 61 72", true);
```

## Supported Data Types

### Encoding (CF → MessagePack)

| ColdFusion Type | MessagePack Format | Notes |
|----------------|-------------------|-------|
| `null` | nil (0xc0) | |
| `true/false` | bool (0xc2/0xc3) | |
| Integer | int format family | Automatically selects optimal size |
| Float/Double | float32/float64 | |
| String | str format family | UTF-8 encoded |
| Binary | bin format family | |
| Array | array format family | |
| Struct | map format family | Keys converted to strings |

### Decoding (MessagePack → CF)

| MessagePack Format | ColdFusion Type | Notes |
|-------------------|----------------|-------|
| nil | null | |
| bool | Boolean | |
| int family | Numeric | |
| float family | Numeric | |
| str family | String | UTF-8 decoded |
| bin family | Binary | Byte array |
| array family | Array | |
| map family | Struct | |

## Advanced Examples

### Working with Nested Structures

```cfml
<cfscript>
msgpack = new MessagePack();

data = {
    user: {
        name: "John Doe",
        age: 30,
        email: "john@example.com"
    },
    permissions: ["read", "write", "admin"],
    metadata: {
        created: "2024-01-01",
        active: true
    }
};

encoded = msgpack.encode(data);
decoded = msgpack.decode(encoded);
</cfscript>
```

### Binary Data

```cfml
<cfscript>
msgpack = new MessagePack();

// Encode binary data
binaryData = toBinary(toBase64("Hello World!"));
encoded = msgpack.encode({
    message: "Test",
    binary: binaryData
});

decoded = msgpack.decode(encoded);
// Access binary: decoded.binary
</cfscript>
```

### Arrays

```cfml
<cfscript>
msgpack = new MessagePack();

// Mixed-type array
data = [1, "two", 3.14, true, null, {nested: "object"}];
encoded = msgpack.encode(data);
decoded = msgpack.decode(encoded);
</cfscript>
```

## REST API Integration

### Sending MessagePack from CF

```cfml
<cfscript>
msgpack = new MessagePack();

data = {
    users: queryExecute("SELECT * FROM users"),
    timestamp: now()
};

// Set content type
cfheader(name="Content-Type", value="application/x-msgpack");

// Encode and send
encoded = msgpack.encode(data);
cfcontent(type="application/x-msgpack", variable=encoded, reset=true);
</cfscript>
```

### Receiving MessagePack in CF

```cfml
<cfscript>
msgpack = new MessagePack();

// Get raw POST body
requestBody = getHTTPRequestData().content;

// Decode MessagePack
data = msgpack.decode(requestBody);

// Process the data
writeDump(data);
</cfscript>
```

### Calling External MessagePack API

```cfscript
msgpack = new MessagePack();

// Encode request data
requestData = {
    action: "getUser",
    userId: 123
};
encodedRequest = msgpack.encode(requestData);

// Make HTTP request
http url="https://api.example.com/endpoint" method="POST" result="httpResult" {
    httpparam type="header" name="Content-Type" value="application/x-msgpack";
    httpparam type="body" value=encodedRequest;
}

// Decode response
if (httpResult.statusCode == "200 OK") {
    decoded = msgpack.decode(httpResult.fileContent);
    writeDump(decoded);
}
```

### Hex String for Text-Based Protocols

```cfscript
msgpack = new MessagePack();

// Encode to hex for transmission over text-only protocols
data = {command: "update", value: 42};
hexEncoded = msgpack.encode(data, true);

// Send via URL parameter, form field, or text-based protocol
url = "https://api.example.com/msgpack?data=" & urlEncodedFormat(hexEncoded);

// On receiving end, decode from hex
receivedHex = url.data;
decoded = msgpack.decode(receivedHex, true);
```

### WebSocket with Hex Encoding

```cfscript
msgpack = new MessagePack();

// Encode message as hex for WebSocket text frames
message = {
    type: "chat",
    user: "Alice",
    text: "Hello World"
};

hexMessage = msgpack.encode(message, true);
// Send over WebSocket as text

// On receive, decode from hex
decoded = msgpack.decode(hexMessage, true);
```

## Performance

MessagePack is generally more compact than JSON and faster to encode/decode:

```cfml
<cfscript>
msgpack = new MessagePack();

data = {
    name: "Test User",
    age: 30,
    tags: ["tag1", "tag2", "tag3"],
    active: true
};

// JSON comparison
jsonSize = len(serializeJSON(data));
msgpackSize = arrayLen(msgpack.encode(data));

writeOutput("JSON: #jsonSize# bytes<br>");
writeOutput("MessagePack: #msgpackSize# bytes<br>");
// Typically 20-50% size reduction
</cfscript>
```

## Compatibility with msgpack-lite (JavaScript)

This implementation is compatible with msgpack-lite and other MessagePack implementations:

### JavaScript (Node.js) Example

```javascript
// Node.js with msgpack-lite
const msgpack = require("msgpack-lite");

// Encode in JS
const buffer = msgpack.encode({foo: "bar", num: 123});

// Send to ColdFusion endpoint...
// ColdFusion can decode it with msgpack.decode(buffer)
```

### ColdFusion

```cfml
<cfscript>
// Receive from JavaScript
msgpack = new MessagePack();
decoded = msgpack.decode(receivedBuffer);
// {foo: "bar", num: 123}
</cfscript>
```

## Limitations

1. **Integer Range**: ColdFusion numbers have limitations with very large integers (>2^53). For uint64/int64 values outside CF's range, they are returned as Java Long objects.

2. **Binary vs Strings**: MessagePack distinguishes between binary and string data. In CF, binary data is represented as byte arrays.

3. **Map Keys**: MessagePack maps can have any type as keys, but ColdFusion structs require string keys. Non-string keys are automatically converted to strings during decoding.

4. **Extension Types**: The JavaScript msgpack-lite library supports custom extension types (0x00-0x7F). This CF port currently does not support extension types, but they can be added if needed.

## Error Handling

```cfml
<cfscript>
msgpack = new MessagePack();

try {
    // Invalid data
    decoded = msgpack.decode([0xff, 0xff, 0xff]);
} catch (any e) {
    writeOutput("Error: #e.message#");
    // Error: Unknown MessagePack type: ...
}
</cfscript>
```

## Testing

Run the included test file:

```
http://yourserver/MessagePackTest.cfm
```

This will run comprehensive tests covering:
- Basic data types
- Nested structures
- Arrays
- Binary data
- Unicode/special characters
- Performance benchmarks
- Size comparisons with JSON

## MessagePack Format Reference

The implementation follows the [MessagePack specification](https://github.com/msgpack/msgpack/blob/master/spec.md):

- **nil**: `0xc0`
- **false**: `0xc2`
- **true**: `0xc3`
- **Positive fixint**: `0x00` - `0x7f`
- **Negative fixint**: `0xe0` - `0xff`
- **uint8/16/32/64**: `0xcc` - `0xcf`
- **int8/16/32/64**: `0xd0` - `0xd3`
- **float32**: `0xca`
- **float64**: `0xcb`
- **fixstr**: `0xa0` - `0xbf`
- **str8/16/32**: `0xd9` - `0xdb`
- **bin8/16/32**: `0xc4` - `0xc6`
- **fixarray**: `0x90` - `0x9f`
- **array16/32**: `0xdc` - `0xdd`
- **fixmap**: `0x80` - `0x8f`
- **map16/32**: `0xde` - `0xdf`

## Contributing

This is a direct port of msgpack-lite to ColdFusion. If you find bugs or have improvements, please submit issues or pull requests.

## License

MIT License (same as msgpack-lite)

## Credits

Based on [msgpack-lite](https://github.com/kawanet/msgpack-lite) by Yusuke Kawasaki

Ported to ColdFusion with compatibility for CF2016+ and Java 11+

## See Also

- [MessagePack Official Site](https://msgpack.org/)
- [msgpack-lite (JavaScript)](https://github.com/kawanet/msgpack-lite)
- [MessagePack Specification](https://github.com/msgpack/msgpack/blob/master/spec.md)
