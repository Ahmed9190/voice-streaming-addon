#!/usr/bin/env python3
"""
Test WebSocket connection to the WebRTC server.
This script verifies that the WebSocket endpoint is accessible.
"""

import asyncio
import json
import sys

import websockets


async def test_websocket_connection():
    """Test connection to the WebRTC WebSocket server."""

    # Test different possible URLs
    test_urls = [
        "ws://localhost:8080/ws",
        "ws://127.0.0.1:8080/ws",
    ]

    for uri in test_urls:
        print(f"\n{'=' * 60}")
        print(f"Testing connection to: {uri}")
        print(f"{'=' * 60}")

        try:
            async with websockets.connect(uri, ping_timeout=5) as websocket:
                print("✅ Connected successfully!")

                # Test sending a message
                test_message = {"type": "get_available_streams"}
                await websocket.send(json.dumps(test_message))
                print(f"📤 Sent: {test_message}")

                # Wait for a response (with timeout)
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                    print(f"📥 Received: {response}")

                    # Parse and display the response
                    try:
                        data = json.loads(response)
                        print(f"✅ Valid JSON response: {json.dumps(data, indent=2)}")
                    except json.JSONDecodeError:
                        print(f"⚠️  Response is not JSON: {response}")

                except asyncio.TimeoutError:
                    print("⏱️  No response received (timeout after 2s)")
                    print("   This might be normal if no streams are available")

                print("\n✅ WebSocket connection test PASSED")
                return True

        except ConnectionRefusedError:
            print(f"❌ Connection refused - Server not running on {uri}")
        except websockets.exceptions.InvalidStatusCode as e:
            print(f"❌ Invalid status code: {e}")
        except Exception as e:
            print(f"❌ Error: {type(e).__name__}: {e}")

    print("\n" + "=" * 60)
    print("❌ All connection attempts failed")
    print("=" * 60)
    print("\nTroubleshooting:")
    print("1. Ensure the WebRTC server is running")
    print("2. Check if it's listening on port 8080")
    print("3. Verify the endpoint is /ws")
    print("4. Check firewall settings")
    return False


if __name__ == "__main__":
    print("WebRTC WebSocket Connection Test")
    print("=" * 60)

    success = asyncio.run(test_websocket_connection())
    sys.exit(0 if success else 1)
