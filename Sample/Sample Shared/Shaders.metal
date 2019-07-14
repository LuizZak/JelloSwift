//
//  Shaders.metal
//  Sample
//
//  Created by Luiz Fernando Silva on 12/07/19.
//  Copyright © 2019 Luiz Fernando Silva. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position;
    packed_float4 color;
};

struct VertexOut {
    float4 computedPosition [[position]];
    float4 color;
};

vertex VertexOut basic_vertex( // 1
                              const device VertexIn* vertex_array [[ buffer(0) ]], // 2
                              unsigned int vid [[ vertex_id ]]) {                  // 3
    // 4
    VertexIn v = vertex_array[vid];
    
    // 5
    VertexOut outVertex = VertexOut();
    outVertex.computedPosition = float4(v.position, 1.0);
    outVertex.color = v.color;
    return outVertex;
}

fragment float4 basic_fragment(VertexOut interpolated [[stage_in]]) {
    return float4(interpolated.color);
}
