<cfscript>
/**
 * MessagePack Test and Example Usage
 * Demonstrates encoding and decoding with msgpack-lite compatibility
 */

// Create MessagePack instance
msgpack = new msgPack();

writeDump(var="=== MessagePack ColdFusion Port Tests ===", format="text");
writeOutput("<br><br>");

// Test 1: Simple Object (matches msgpack-lite example)
writeDump(var="Test 1: Simple Object", format="text");
data1 = {foo: "bar"};
encoded1 = msgpack.encode(data1);
decoded1 = msgpack.decode(encoded1);

writeDump(var="Original: ", format="text");
writeDump(data1);
writeDump(var="Encoded bytes: ", format="text");
writeDump(encoded1);
writeDump(var="Decoded: ", format="text");
writeDump(decoded1);
writeOutput("<br><br>");

// Test 2: Numbers (various types)
writeDump(var="Test 2: Number Types", format="text");
data2 = {
    positiveInt: 123,
    negativeInt: -456,
    float: 3.14159,
    zero: 0,
    smallPositive: 42,
    smallNegative: -15
};
encoded2 = msgpack.encode(data2);
decoded2 = msgpack.decode(encoded2);

writeDump(var="Original: ", format="text");
writeDump(data2);
writeDump(var="Decoded: ", format="text");
writeDump(decoded2);
writeOutput("<br><br>");

// Test 3: Nested Structures
writeDump(var="Test 3: Nested Structures", format="text");
data3 = {
    user: {
        name: "John Doe",
        age: 30,
        active: true
    },
    tags: ["admin", "user", "moderator"],
    metadata: {
        created: "2024-01-01",
        updated: "2024-10-28"
    }
};
encoded3 = msgpack.encode(data3);
decoded3 = msgpack.decode(encoded3);

writeDump(var="Original: ", format="text");
writeDump(data3);
writeDump(var="Decoded: ", format="text");
writeDump(decoded3);
writeOutput("<br><br>");

// Test 4: Arrays
writeDump(var="Test 4: Arrays", format="text");
data4 = [1, 2, 3, "four", 5.5, true, false, javacast("null", 0)];
encoded4 = msgpack.encode(data4);
decoded4 = msgpack.decode(encoded4);

writeDump(var="Original: ", format="text");
writeDump(data4);
writeDump(var="Decoded: ", format="text");
writeDump(decoded4);
writeOutput("<br><br>");

// Test 5: Boolean Values
writeDump(var="Test 5: Boolean Values", format="text");
data5 = {
    isActive: true,
    isDeleted: false,
    hasPermission: true
};
encoded5 = msgpack.encode(data5);
decoded5 = msgpack.decode(encoded5);

writeDump(var="Original: ", format="text");
writeDump(data5);
writeDump(var="Decoded: ", format="text");
writeDump(decoded5);
writeOutput("<br><br>");

// Test 6: Null/Empty Values
writeDump(var="Test 6: Null Values", format="text");
data6 = {
    value1: javacast("null", 0),
    value2: "",
    value3: "something"
};
encoded6 = msgpack.encode(data6);
decoded6 = msgpack.decode(encoded6);

writeDump(var="Original: ", format="text");
writeDump(data6);
writeDump(var="Decoded: ", format="text");
writeDump(decoded6);
writeOutput("<br><br>");

// Test 7: Binary Data
writeDump(var="Test 7: Binary Data", format="text");
binaryData = toBinary(toBase64("Hello World!"));
data7 = {
    message: "Test",
    binary: binaryData
};
encoded7 = msgpack.encode(data7);
decoded7 = msgpack.decode(encoded7);

writeDump(var="Original: ", format="text");
writeDump(data7);
writeDump(var="Decoded: ", format="text");
writeDump(decoded7);

// Convert Java byte array to Base64 string for comparison
try {
    decodedBinary = decoded7.binary;

    // Convert original to base64
    originalBase64 = toBase64(data7.binary);

    // Convert decoded (Java byte array) to base64
    if (isArray(decodedBinary)) {
        // Use Java Base64 encoder for Java byte array
        base64Encoder = createObject("java", "java.util.Base64").getEncoder();
        decodedBase64 = toString(base64Encoder.encodeToString(decodedBinary));
    } else {
        decodedBase64 = toBase64(decodedBinary);
    }

    writeDump(var="Binary content matches: #originalBase64 eq decodedBase64#", format="text");
} catch (any e) {
    writeDump(var="Binary comparison error: #e.message#", format="text");
}
writeOutput("<br><br>");

// Test 8: Large Array
writeDump(var="Test 8: Large Array (20 items)", format="text");
data8 = [];
for (i = 1; i <= 20; i++) {
    arrayAppend(data8, {id: i, name: "Item #i#", value: i * 10});
}
encoded8 = msgpack.encode(data8);
decoded8 = msgpack.decode(encoded8);

writeDump(var="Array length: #arrayLen(data8)#", format="text");
writeDump(var="Decoded length: #arrayLen(decoded8)#", format="text");

// Use structKeyExists to safely check if id field exists
try {
    if (isStruct(data8[1]) && isStruct(decoded8[1])) {
        writeDump(var="First item ID matches: #data8[1].id eq decoded8[1].id#", format="text");
        writeDump(var="First item name matches: #data8[1].name eq decoded8[1].name#", format="text");
    }
} catch (any e) {
    writeDump(var="Array comparison error: #e.message#", format="text");
}
writeOutput("<br><br>");

// Test 9: Edge Cases - Special Characters
writeDump(var="Test 9: Unicode/Special Characters", format="text");
data9 = {
    english: "Hello World",
    spanish: "¡Hola Mundo!",
    chinese: "你好世界",
    emoji: "🌍🚀💻",
    special: "Line1" & chr(10) & "Line2" & chr(9) & "Tab"
};
encoded9 = msgpack.encode(data9);
decoded9 = msgpack.decode(encoded9);

writeDump(var="Original: ", format="text");
writeDump(data9);
writeDump(var="Decoded: ", format="text");
writeDump(decoded9);
writeOutput("<br><br>");

// Test 10: Performance Test
writeDump(var="Test 10: Performance Test (1000 iterations)", format="text");
perfData = {
    users: [
        {id: 1, name: "Alice", email: "alice@example.com", active: true},
        {id: 2, name: "Bob", email: "bob@example.com", active: false},
        {id: 3, name: "Charlie", email: "charlie@example.com", active: true}
    ],
    metadata: {
        total: 3,
        page: 1,
        timestamp: now()
    }
};

startTime = getTickCount();
for (i = 1; i <= 1000; i++) {
    temp = msgpack.encode(perfData);
}
encodeTime = getTickCount() - startTime;

// Get one encoded result for decode test
encodedPerf = msgpack.encode(perfData);

startTime = getTickCount();
for (i = 1; i <= 1000; i++) {
    temp = msgpack.decode(encodedPerf);
}
decodeTime = getTickCount() - startTime;

writeDump(var="Encode 1000 times: #encodeTime#ms", format="text");
writeDump(var="Decode 1000 times: #decodeTime#ms", format="text");
writeDump(var="Encoded size: #arrayLen(encodedPerf)# bytes", format="text");
writeOutput("<br><br>");

// Test 11: Compatibility - Compare with JSON
writeDump(var="Test 11: Size Comparison with JSON", format="text");
compData = {
    name: "Test User",
    age: 30,
    active: true,
    tags: ["tag1", "tag2", "tag3"],
    metadata: {
        created: "2024-01-01",
        score: 95.5
    }
};

jsonEncoded = charsetDecode(serializeJSON(compData), "UTF-8");
msgpackEncoded = msgpack.encode(compData);

writeDump(var="JSON size: #arrayLen(jsonEncoded)# bytes", format="text");
writeDump(var="MessagePack size: #arrayLen(msgpackEncoded)# bytes", format="text");
writeDump(var="Size reduction: #numberFormat((1 - arrayLen(msgpackEncoded)/arrayLen(jsonEncoded)) * 100, '0.00')#%", format="text");
writeOutput("<br><br>");

// Test 12: Hex Encoding/Decoding
writeDump(var="Test 12: Hex String Encoding/Decoding", format="text");
data12 = {foo: "bar", num: 123};

// Encode to hex string
hexEncoded = msgpack.encode(data12, true);
writeDump(var="Hex encoded: #hexEncoded#", format="text");

// Decode from hex string
hexDecoded = msgpack.decode(hexEncoded, true);
writeDump(var="Hex decoded: ", format="text");
writeDump(hexDecoded);

// Verify it matches
writeDump(var="Hex round-trip successful: #hexDecoded.foo eq data12.foo AND hexDecoded.num eq data12.num#", format="text");

// Test with spaces/formatting in hex string
hexWithSpaces = "81 A3 66 6F 6F A3 62 61 72";
hexDecodedSpaces = msgpack.decode(hexWithSpaces, true);
writeDump(var="Decoded from formatted hex: ", format="text");
writeDump(hexDecodedSpaces);
writeOutput("<br><br>");

writeDump(var="=== All Tests Complete ===", format="text");
</cfscript>

<!---
Alternative REST API Usage Example:

<script>
// Example: REST API endpoint that returns MessagePack
function getUserData() {
    var msgpack = new MessagePack();
    var data = {
        users: queryToArray(queryExecute("SELECT * FROM users")),
        timestamp: now()
    };

    // Set content type for MessagePack
    header name="Content-Type" value="application/x-msgpack";

    // Return encoded data
    var encoded = msgpack.encode(data);
    content type="application/x-msgpack" variable=encoded reset=true;
}

// Example: REST API endpoint that accepts MessagePack
function saveUserData() {
    var msgpack = new MessagePack();

    // Get raw POST body
    var requestBody = getHTTPRequestData().content;

    // Decode MessagePack
    var data = msgpack.decode(requestBody);

    // Process data
    // ... database operations ...

    // Return response
    return {success: true, id: data.id};
}
</script>
--->
