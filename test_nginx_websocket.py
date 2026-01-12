#!/usr/bin/env python3
"""
Test WebSocket connection through Nginx proxy.
"""

import asyncio
import json
import ssl

import websockets


async def test_nginx_websocket():
    """Test WebSocket connection through Nginx HTTPS proxy."""

    # Create SSL context that doesn't verify certificates (for self-signed certs)
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE

    uri = "wss://localhost/ws"

    print(f"Testing WebSocket connection to: {uri}")
    print("=" * 60)

    try:
        async with websockets.connect(
            uri, ssl=ssl_context, ping_timeout=5
        ) as websocket:
            print("✅ Connected successfully!")
            print(f"   WebSocket state: {websocket.state.name}")

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
                    print("✅ Valid JSON response:")
                    print(json.dumps(data, indent=2))
                except json.JSONDecodeError:
                    print(f"⚠️  Response is not JSON: {response}")

            except asyncio.TimeoutError:
                print("⏱️  No response received (timeout after 2s)")
                print("   This is normal if no streams are available")

            print("\n✅ WebSocket connection through Nginx WORKS!")
            return True

    except ConnectionRefusedError:
        print("❌ Connection refused")
        print("   - Check if Nginx is running: docker ps | grep nginx")
        print("   - Check if WebRTC server is running on port 8080")
        return False
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"❌ Invalid status code: {e}")
        print("   - Check Nginx configuration")
        print("   - Check Nginx logs: docker logs ha-nginx")
        return False
    except ssl.SSLError as e:
        print(f"❌ SSL Error: {e}")
        print("   - Check SSL certificates")
        print("   - Try HTTP instead: ws://localhost/ws")
        return False
    except Exception as e:
        print(f"❌ Error: {type(e).__name__}: {e}")
        return False


if __name__ == "__main__":
    print("WebSocket Connection Test (Through Nginx)")
    print("=" * 60)
    print()

    success = asyncio.run(test_nginx_websocket())

    if success:
        print("\n" + "=" * 60)
        print("✅ SUCCESS: Nginx WebSocket proxy is working correctly!")
        print("=" * 60)
        print("\nYou can now use the Voice Receiving Card with:")
        print("  Server URL: https://localhost/ws")
        print("  (or leave empty to use default)")
    else:
        print("\n" + "=" * 60)
        print("❌ FAILED: WebSocket connection through Nginx failed")
        print("=" * 60)
        print("\nTroubleshooting:")
        print("1. Check Nginx is running: docker ps | grep nginx")
        print("2. Check Nginx config: docker exec ha-nginx nginx -t")
        print("3. Check Nginx logs: docker logs ha-nginx")
        print("4. Check WebRTC server: curl http://localhost:8080/ws")
        print("5. Reload Nginx: docker exec ha-nginx nginx -s reload")
