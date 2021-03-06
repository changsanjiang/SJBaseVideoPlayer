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

