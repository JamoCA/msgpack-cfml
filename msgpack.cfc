/**
 * MessagePack Encoder/Decoder for ColdFusion 2016+
 * Based on msgpack-lite JavaScript implementation
 * Requires Java 11+
 *
 * Updated 11/29/2025 17:14 Pacific - Tested in CF2016-2025, Lucee 6 & BoxLang
 *   
 * Usage:
 *   msgpack = new MessagePack();
 *   
 *   // Encoding
 *   data = {foo: "bar", num: 123};
 *   encoded = msgpack.encode(data);
 *   
 *   // Decoding
 *   decoded = msgpack.decode(encoded);
 */
component displayname="MessagePack" {

    // Java classes for binary operations
    variables.ByteArrayOutputStream = createObject("java", "java.io.ByteArrayOutputStream");
    variables.ByteArrayInputStream = createObject("java", "java.io.ByteArrayInputStream");
    variables.DataOutputStream = createObject("java", "java.io.DataOutputStream");
    variables.DataInputStream = createObject("java", "java.io.DataInputStream");
    variables.ByteBuffer = createObject("java", "java.nio.ByteBuffer");
    
    // MessagePack format constants (hex values converted to decimal)
    // Format family constants
    variables.NIL = javacast("int", 192);              // 0xc0
    variables.FALSE = javacast("int", 194);            // 0xc2
    variables.TRUE = javacast("int", 195);             // 0xc3
    
    // Binary formats
    variables.BIN8 = javacast("int", 196);             // 0xc4
    variables.BIN16 = javacast("int", 197);            // 0xc5
    variables.BIN32 = javacast("int", 198);            // 0xc6
    
    // Float formats
    variables.FLOAT32 = javacast("int", 202);          // 0xca
    variables.FLOAT64 = javacast("int", 203);          // 0xcb
    
    // Unsigned int formats
    variables.UINT8 = javacast("int", 204);            // 0xcc
    variables.UINT16 = javacast("int", 205);           // 0xcd
    variables.UINT32 = javacast("int", 206);           // 0xce
    variables.UINT64 = javacast("int", 207);           // 0xcf
    
    // Signed int formats
    variables.INT8 = javacast("int", 208);             // 0xd0
    variables.INT16 = javacast("int", 209);            // 0xd1
    variables.INT32 = javacast("int", 210);            // 0xd2
    variables.INT64 = javacast("int", 211);            // 0xd3
    
    // String formats
    variables.STR8 = javacast("int", 217);             // 0xd9
    variables.STR16 = javacast("int", 218);            // 0xda
    variables.STR32 = javacast("int", 219);            // 0xdb
    
    // Array formats
    variables.ARRAY16 = javacast("int", 220);          // 0xdc
    variables.ARRAY32 = javacast("int", 221);          // 0xdd
    
    // Map formats
    variables.MAP16 = javacast("int", 222);            // 0xde
    variables.MAP32 = javacast("int", 223);            // 0xdf
    
    // Format ranges
    variables.POSITIVE_FIXINT_MAX = javacast("int", 127);      // 0x7f
    variables.FIXMAP_PREFIX = javacast("int", 128);            // 0x80
    variables.FIXMAP_MAX = javacast("int", 143);               // 0x8f
    variables.FIXARRAY_PREFIX = javacast("int", 144);          // 0x90
    variables.FIXARRAY_MAX = javacast("int", 159);             // 0x9f
    variables.FIXSTR_PREFIX = javacast("int", 160);            // 0xa0
    variables.FIXSTR_MAX = javacast("int", 191);               // 0xbf
    variables.NEGATIVE_FIXINT_MIN = javacast("int", 224);      // 0xe0
    
    // Bit masks
    variables.MASK_8BIT = javacast("int", 255);                // 0xff
    variables.MASK_16BIT = javacast("int", 65535);             // 0xffff
    variables.MASK_32BIT = javacast("long", 4294967295);       // 0xffffffff

	/**
     * Initialize MessagePack encoder/decoder
     */
    public function init() {
        return this;
    }
    
    /**
     * Encode a ColdFusion value to MessagePack binary format
     * @param value The value to encode (struct, array, string, number, boolean, null)
     * @param asHex Return as hex string instead of binary (default: false)
     * @return byte array in MessagePack format or hex string
     */
    public any function encode(any value, boolean asHex=false) {
        var baos = variables.ByteArrayOutputStream.init();
        var dos = variables.DataOutputStream.init(baos);
        try {
			if (!isdefined("arguments.value") || isnull(arguments.value)){
				encodeNil(dos);
			} else {
				encodeValue(dos, arguments.value);
			}
            dos.flush();
            var bytes = baos.toByteArray();
            
            // Convert to hex string if requested
            if (arguments.asHex) {
                return binaryToHex(bytes);
            }
            
            return bytes;
        } finally {
            dos.close();
            baos.close();
        }
    }
    
    /**
     * Decode MessagePack binary data to ColdFusion value
     * @param data Binary data, byte array, or hex string
     * @param isHex Indicates if data is a hex string (default: false)
     * @return Decoded ColdFusion value
     */
    public any function decode(required any data, boolean isHex=false) {
        var bytes = arguments.data;
        
        // Convert hex string to binary if needed
        if (arguments.isHex) {
            bytes = hexToBinary(arguments.data);
        }
        // Handle binary object
        else if (isBinary(bytes)) {
            bytes = toBinary(bytes);
        }
        
        var bais = variables.ByteArrayInputStream.init(bytes);
        var dis = variables.DataInputStream.init(bais);
        
        try {
            var result = decodeValue(dis);
            // Unwrap the result if it's not a container type
			if (isdefined("result")){
				return unwrapValue(result);
			}
        } finally {
            dis.close();
            bais.close();
        }
    }
    
    /**
     * Convert binary data to hex string
     * @param bytes Binary data or byte array
     * @return Hex string representation
     */
    private string function binaryToHex(required any bytes) {
        var hexString = createObject("java", "java.lang.StringBuilder").init();
        var byteArray = arguments.bytes;
        
        for (var i = 1; i <= arrayLen(byteArray); i++) {
            var b = byteArray[i];
            // Convert signed byte to unsigned
            var unsigned = bitAnd(b, variables.MASK_8BIT);
            // Format as 2-digit hex
            var hex = uCase(formatBaseN(unsigned, 16));
            if (len(hex) == 1) {
                hexString.append("0");
            }
            hexString.append(hex);
        }
        
        return hexString.toString();
    }
    
    /**
     * Convert hex string to binary data
     * @param hexString Hex string (e.g., "81A3666F6F")
     * @return Binary byte array
     */
    private binary function hexToBinary(required string hexString) {
        var hex = replace(arguments.hexString, " ", "", "ALL");
        hex = replace(hex, "-", "", "ALL");
        hex = replace(hex, ":", "", "ALL");
        
        // Validate hex string
        if (len(hex) mod 2 != 0) {
            throw(type="MessagePack.HexError", message="Hex string must have an even number of characters");
        }
        
        if (!reFind("^[0-9A-Fa-f]+$", hex)) {
            throw(type="MessagePack.HexError", message="Invalid hex string - contains non-hexadecimal characters");
        }
        
        var byteCount = len(hex) / 2;
        var byteClass = createObject("java", "java.lang.Byte").TYPE;
        var bytes = createObject("java", "java.lang.reflect.Array").newInstance(byteClass, javacast("int", byteCount));
        var arrayReflect = createObject("java", "java.lang.reflect.Array");
        
        for (var i = 0; i < byteCount; i++) {
            var hexByte = mid(hex, (i * 2) + 1, 2);
            var byteValue = inputBaseN(hexByte, 16);
            
            // Convert to signed byte if necessary
            if (byteValue > 127) {
                byteValue = byteValue - 256;
            }
            
            // Use Array.set() instead of direct assignment
            arrayReflect.set(bytes, javacast("int", i), javacast("byte", byteValue));
        }
        
        return bytes;
    }
    
    /**
     * Unwrap decoded values, preserving types
     */
    private any function unwrapValue(required any value) {
        // Handle arrays
        if (isArray(arguments.value)) {
            var arr = [];
            for (var i = 1; i <= arrayLen(arguments.value); i++) {
                try {
                    var item = arguments.value[i];
                    arrayAppend(arr, unwrapValue(item));
                } catch (any e) {
                    // Null value in array
                    arrayAppend(arr, javacast("null", 0));
                }
            }
            return arr;
        }
        
        // Handle structs/maps
        if (isStruct(arguments.value) && !structKeyExists(arguments.value, "__msgpack_type")) {
            var map = {};
            var keys = structKeyArray(arguments.value);
            for (var key in keys) {
                try {
                    var val = arguments.value[key];
                    if (isNull(val)) {
                        structInsert(map, key, javacast("null", 0));
                    } else {
                        map[key] = unwrapValue(val);
                    }
                } catch (any e) {
                    // Null value in struct
                    structInsert(map, key, javacast("null", 0));
                }
            }
            return map;
        }
        
        // Handle wrapped primitives with type info
        if (isStruct(arguments.value) && structKeyExists(arguments.value, "__msgpack_type")) {
            return arguments.value.__msgpack_value;
        }
        
        return arguments.value;
    }
    
    // ===== ENCODING METHODS =====
    
    private void function encodeValue(required any dos, required any value) {
        // Check for null first - use structKeyExists to avoid null reference errors
        var isNullValue = false;
        try {
            isNullValue = isNull(arguments.value);
        } catch (any e) {
            isNullValue = true;
        }
        
        if (isNullValue) {
            encodeNil(arguments.dos);
        } else if (isNumeric(arguments.value)) {
            // Check numeric BEFORE boolean since isBoolean() returns true for 0, 1
            encodeNumber(arguments.dos, arguments.value);
        } else if (isBoolean(arguments.value)) {
            encodeBoolean(arguments.dos, arguments.value);
        } else if (isSimpleValue(arguments.value)) {
            encodeString(arguments.dos, arguments.value);
        } else if (isBinary(arguments.value)) {
            encodeBinary(arguments.dos, arguments.value);
        } else if (isArray(arguments.value)) {
            encodeArray(arguments.dos, arguments.value);
        } else if (isStruct(arguments.value)) {
            encodeMap(arguments.dos, arguments.value);
        } else {
            throw(type="MessagePack.EncodeError", message="Unsupported data type for encoding");
        }
    }
    
    private void function encodeNil(required any dos) {
        arguments.dos.writeByte(variables.NIL);
    }
    
    private void function encodeBoolean(required any dos, required boolean value) {
        arguments.dos.writeByte(arguments.value ? variables.TRUE : variables.FALSE);
    }
    
    private void function encodeNumber(required any dos, required numeric value) {
        var num = arguments.value;
        
        // Check if integer
        if (num == int(num)) {
            var intVal = javacast("long", int(num));
            
            // Positive fixint (0 to 127)
            if (intVal >= 0 && intVal <= 127) {
                arguments.dos.writeByte(javacast("int", intVal));
            }
            // Negative fixint (-32 to -1)
            else if (intVal >= -32 && intVal < 0) {
                arguments.dos.writeByte(javacast("int", intVal));
            }
            // uint8
            else if (intVal >= 0 && intVal <= 255) {
                arguments.dos.writeByte(variables.UINT8);
                arguments.dos.writeByte(javacast("int", intVal));
            }
            // uint16
            else if (intVal >= 0 && intVal <= 65535) {
                arguments.dos.writeByte(variables.UINT16);
                arguments.dos.writeShort(javacast("int", intVal));
            }
            // uint32
            else if (intVal >= 0 && intVal <= 4294967295) {
                arguments.dos.writeByte(variables.UINT32);
				if (intVal gt 2147483647){
					arguments.dos.writeLong(intVal);
				} else {
					arguments.dos.writeInt(javacast("int", intVal));
				}
            }
            // int8
            else if (intVal >= -128 && intVal < 0) {
                arguments.dos.writeByte(variables.INT8);
                arguments.dos.writeByte(javacast("int", intVal));
            }
            // int16
            else if (intVal >= -32768 && intVal < 0) {
                arguments.dos.writeByte(variables.INT16);
                arguments.dos.writeShort(javacast("int", intVal));
            }
            // int32
            else if (intVal >= -2147483648 && intVal < 0) {
                arguments.dos.writeByte(variables.INT32);
                arguments.dos.writeInt(javacast("int", intVal));
            }
            // int64
            else {
                arguments.dos.writeByte(variables.INT64);
                arguments.dos.writeLong(intVal);
            }
        } else {
            // Float64
			arguments.dos.writeByte(variables.FLOAT64);
			arguments.dos.writeDouble(javacast("double", num));
        }
    }
    
    private void function encodeString(required any dos, required string value) {
        var strBytes = charsetDecode(arguments.value, "UTF-8");
        var len = arrayLen(strBytes);
        
        // fixstr (up to 31 bytes)
        if (len <= 31) {
            arguments.dos.writeByte(javacast("int", variables.FIXSTR_PREFIX + len));
        }
        // str8
        else if (len <= 255) {
            arguments.dos.writeByte(variables.STR8);
            arguments.dos.writeByte(javacast("int", len));
        }
        // str16
        else if (len <= 65535) {
            arguments.dos.writeByte(variables.STR16);
            arguments.dos.writeShort(javacast("int", len));
        }
        // str32
        else {
            arguments.dos.writeByte(variables.STR32);
            arguments.dos.writeInt(javacast("int", len));
        }
        
        arguments.dos.write(strBytes, 0, len);
    }
    
    private void function encodeBinary(required any dos, required any value) {
        var bytes = toBinary(arguments.value);
        var len = arrayLen(bytes);
        
        // bin8
        if (len <= 255) {
            arguments.dos.writeByte(variables.BIN8);
            arguments.dos.writeByte(javacast("int", len));
        }
        // bin16
        else if (len <= 65535) {
            arguments.dos.writeByte(variables.BIN16);
            arguments.dos.writeShort(javacast("int", len));
        }
        // bin32
        else {
            arguments.dos.writeByte(variables.BIN32);
            arguments.dos.writeInt(javacast("int", len));
        }
        
        arguments.dos.write(bytes, 0, len);
    }
    
    private void function encodeArray(required any dos, required array value) {
        var len = arrayLen(arguments.value);
        
        // fixarray (up to 15 elements)
        if (len <= 15) {
            arguments.dos.writeByte(javacast("int", variables.FIXARRAY_PREFIX + len));
        }
        // array16
        else if (len <= 65535) {
            arguments.dos.writeByte(variables.ARRAY16);
            arguments.dos.writeShort(javacast("int", len));
        }
        // array32
        else {
            arguments.dos.writeByte(variables.ARRAY32);
            arguments.dos.writeInt(javacast("int", len));
        }
        
        // Use indexed loop to avoid issues with null values
        for (var i = 1; i <= len; i++) {
            try {
                var item = arguments.value[i];
                var itemIsNull = isNull(item);
            } catch (any e) {
                // If we get an error accessing the item, treat it as null
                var itemIsNull = true;
            }
            
            if (itemIsNull) {
                encodeNil(arguments.dos);
            } else {
                encodeValue(arguments.dos, arguments.value[i]);
            }
        }
    }
    
    private void function encodeMap(required any dos, required struct value) {
        var keys = structKeyArray(arguments.value);
        var len = arrayLen(keys);
        
        // fixmap (up to 15 key-value pairs)
        if (len <= 15) {
            arguments.dos.writeByte(javacast("int", variables.FIXMAP_PREFIX + len));
        }
        // map16
        else if (len <= 65535) {
            arguments.dos.writeByte(variables.MAP16);
            arguments.dos.writeShort(javacast("int", len));
        }
        // map32
        else {
            arguments.dos.writeByte(variables.MAP32);
            arguments.dos.writeInt(javacast("int", len));
        }
        
        for (var key in keys) {
            encodeString(arguments.dos, key);
            
            // Handle null values in struct
            var valueIsNull = false;
            try {
                var structValue = arguments.value[key];
                valueIsNull = isNull(structValue);
            } catch (any e) {
                // If we get an error accessing the value, treat it as null
                valueIsNull = true;
            }
            
            if (valueIsNull) {
                encodeNil(arguments.dos);
            } else {
                encodeValue(arguments.dos, arguments.value[key]);
            }
        }
    }
    
    // ===== DECODING METHODS =====
    
    private any function decodeValue(required any dis) {
        var firstByte = 0;
        
        try {
            firstByte = arguments.dis.readByte();
        } catch (java.io.EOFException e) {
            throw(type="MessagePack.DecodeError", message="Unexpected end of MessagePack data stream");
        }
        
        var type = bitAnd(firstByte, variables.MASK_8BIT);
        
        // Positive fixint (0x00 - 0x7f)
        if (type <= variables.POSITIVE_FIXINT_MAX) {
            return wrapNumber(type);
        }
        
        // fixmap (0x80 - 0x8f)
        if (type >= variables.FIXMAP_PREFIX && type <= variables.FIXMAP_MAX) {
            return decodeMap(arguments.dis, type - variables.FIXMAP_PREFIX);
        }
        
        // fixarray (0x90 - 0x9f)
        if (type >= variables.FIXARRAY_PREFIX && type <= variables.FIXARRAY_MAX) {
            return decodeArray(arguments.dis, type - variables.FIXARRAY_PREFIX);
        }
        
        // fixstr (0xa0 - 0xbf)
        if (type >= variables.FIXSTR_PREFIX && type <= variables.FIXSTR_MAX) {
            return decodeString(arguments.dis, type - variables.FIXSTR_PREFIX);
        }
        
        // nil
        if (type == variables.NIL) {
            return javaCast("null", "");
        }
        
        // false
        if (type == variables.FALSE) {
            return wrapBoolean(false);
        }
        
        // true
        if (type == variables.TRUE) {
            return wrapBoolean(true);
        }
        
        // bin8
        if (type == variables.BIN8) {
            var len = bitAnd(arguments.dis.readByte(), variables.MASK_8BIT);
            return decodeBinary(arguments.dis, len);
        }
        
        // bin16
        if (type == variables.BIN16) {
            var len = bitAnd(arguments.dis.readShort(), variables.MASK_16BIT);
            return decodeBinary(arguments.dis, len);
        }
        
        // bin32
        if (type == variables.BIN32) {
            var len = arguments.dis.readInt();
            return decodeBinary(arguments.dis, len);
        }
        
        // float32
        if (type == variables.FLOAT32) {
            return wrapNumber(arguments.dis.readFloat());
        }
        
        // float64
        if (type == variables.FLOAT64) {
            return wrapNumber(arguments.dis.readDouble());
        }
        
        // uint8
        if (type == variables.UINT8) {
            return wrapNumber(bitAnd(arguments.dis.readByte(), variables.MASK_8BIT));
        }
        
        // uint16
        if (type == variables.UINT16) {
            return wrapNumber(bitAnd(arguments.dis.readShort(), variables.MASK_16BIT));
        }
        
        // uint32
        if (type == variables.UINT32) {
            var val = arguments.dis.readInt();
			try {
				return wrapNumber(bitAnd(val, variables.MASK_32BIT));
			} catch (any e) {
				return wrapNumber(val);
			}
        }
        
        // uint64 - represented as Java Long
        if (type == variables.UINT64) {
            var val = arguments.dis.readLong();
            return wrapNumber(val);
        }
        
        // int8
        if (type == variables.INT8) {
            return wrapNumber(arguments.dis.readByte());
        }
        
        // int16
        if (type == variables.INT16) {
            return wrapNumber(arguments.dis.readShort());
        }
        
        // int32
        if (type == variables.INT32) {
            return wrapNumber(arguments.dis.readInt());
        }
        
        // int64
        if (type == variables.INT64) {
            return wrapNumber(arguments.dis.readLong());
        }
        
        // str8
        if (type == variables.STR8) {
            var len = bitAnd(arguments.dis.readByte(), variables.MASK_8BIT);
            return decodeString(arguments.dis, len);
        }
        
        // str16
        if (type == variables.STR16) {
            var len = bitAnd(arguments.dis.readShort(), variables.MASK_16BIT);
            return decodeString(arguments.dis, len);
        }
        
        // str32
        if (type == variables.STR32) {
            var len = arguments.dis.readInt();
            return decodeString(arguments.dis, len);
        }
        
        // array16
        if (type == variables.ARRAY16) {
            var len = bitAnd(arguments.dis.readShort(), variables.MASK_16BIT);
            return decodeArray(arguments.dis, len);
        }
        
        // array32
        if (type == variables.ARRAY32) {
            var len = arguments.dis.readInt();
            return decodeArray(arguments.dis, len);
        }
        
        // map16
        if (type == variables.MAP16) {
            var len = bitAnd(arguments.dis.readShort(), variables.MASK_16BIT);
            return decodeMap(arguments.dis, len);
        }
        
        // map32
        if (type == variables.MAP32) {
            var len = arguments.dis.readInt();
            return decodeMap(arguments.dis, len);
        }
        
        // Negative fixint (0xe0 - 0xff)
        if (type >= variables.NEGATIVE_FIXINT_MIN) {
            // Convert to signed byte
            return wrapNumber(type - 256);
        }
        
        throw(type="MessagePack.DecodeError", message="Unknown MessagePack type: #type#");
    }
    
    /**
     * Wrap a number to preserve type through CF's loose typing
     */
    private struct function wrapNumber(required numeric value) {
        return {
            __msgpack_type: "number",
            __msgpack_value: arguments.value
        };
    }
    
    /**
     * Wrap a boolean to preserve type through CF's loose typing
     */
    private struct function wrapBoolean(required boolean value) {
        return {
            __msgpack_type: "boolean",
            __msgpack_value: arguments.value
        };
    }
    
    private string function decodeString(required any dis, required numeric length) {
        // Create a proper Java byte array
        var byteClass = createObject("java", "java.lang.Byte").TYPE;
        var bytes = createObject("java", "java.lang.reflect.Array").newInstance(byteClass, javacast("int", arguments.length));
        
        arguments.dis.readFully(bytes);
        
        return charsetEncode(bytes, "UTF-8");
    }
    
    private binary function decodeBinary(required any dis, required numeric length) {
        // Create a proper Java byte array
        var byteClass = createObject("java", "java.lang.Byte").TYPE;
        var bytes = createObject("java", "java.lang.reflect.Array").newInstance(byteClass, javacast("int", arguments.length));
        
        arguments.dis.readFully(bytes);
        
        return bytes;
    }
    
    private array function decodeArray(required any dis, required numeric length) {
        var arr = [];
        
        for (var i = 1; i <= arguments.length; i++) {
            arrayAppend(arr, decodeValue(arguments.dis));
        }
        
        return arr;
    }
    
    private struct function decodeMap(required any dis, required numeric length) {
        var map = {};
        
        for (var i = 1; i <= arguments.length; i++) {
            var key = decodeValue(arguments.dis);
            var value = decodeValue(arguments.dis);
            
            // Convert non-string keys to strings
            if (!isSimpleValue(key)) {
                key = toString(key);
            }
            
            // Handle null values - use structInsert to avoid CF null assignment issues
            try {
                if (isNull(value)) {
                    structInsert(map, key, javacast("null", 0));
                } else {
                    map[key] = value;
                }
            } catch (any e) {
                // If value is null and causes an error, explicitly set it
                structInsert(map, key, javacast("null", 0));
            }
        }
        
        return map;
    }

}