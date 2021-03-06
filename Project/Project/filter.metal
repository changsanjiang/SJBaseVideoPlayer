//
//  lucencyFilter.metal
//  SangoLive
//
//  Created by 胡伟伟 on 2020/12/31.
//  Copyright © 2020 Sango. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;



#include <CoreImage/CoreImage.h>

extern "C" { namespace  coreimage {
    
    float4 maskVideoMetal(sample_t s,sample_t m){
        
        return float4(s.rgb,m.r);
        
        }
    }
}

extern "C" { namespace coreimage {
    float4 vignettemetalMask(sample_t image,float r,float g, float b) {
        return float4(image.r *r,image.g *g,image.b *b,image.a);
    }
}}



//extern "C" { namespace coreimage {
//    float4 vignetteMetal(sample_t image, float2 center, float radius, float alpha, destination dest) {
//        float distance2 = distance(dest.coord(), center);
//
//        float darken = 1.0 - (distance2 / radius * alpha);
//        image.rgb *= darken;
//
//        return image.rgba;
//    }
//}}

