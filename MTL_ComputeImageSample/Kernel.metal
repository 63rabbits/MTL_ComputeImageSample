#include <metal_stdlib>
using namespace metal;

constant float3 grayWeight = float3(0.298912, 0.586611, 0.114478);

kernel void computeShader(uint2                           gid        [[ thread_position_in_grid ]],
                          texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                          texture2d<float, access::write> outTexture [[ texture(1) ]]
                          ) {
    // Check a thread’s position in a grid
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        return;
    }

    float4 inColor = inTexture.read(gid);
    float  gray    = dot(inColor.rgb, grayWeight);
    outTexture.write(float4(gray, gray, gray, 1.0), gid);
}
