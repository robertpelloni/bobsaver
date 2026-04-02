#version 420

// original https://www.shadertoy.com/view/tllyz7

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//   Segment numbers
//   ===============
//
//         0
//        ###
//       #   #
//      1#   #2
//       # 3 #
//        ###
//       #   #
//      4#   #5
//       #   #
//        ###
//         6

float segment(vec2 uv,int o){
    
    
    float d = o==1 ? abs(uv.x):abs(uv.y);
   
    d = smoothstep(0.11,0.101,d);
    d *= smoothstep(0.49,0.488,abs(uv.x+uv.y));
    d *= smoothstep(0.49,0.488,abs(uv.x-uv.y));
    
    return d;
}

float digit(vec2 uv,int n){
    float d = 0.0;
    float b = 0.2; // brightness
    uv *= 2.4;
    // segment 0
    if(n!=1 && n!=4){
        d += segment(uv-vec2(0.0,1.0),0);
    } else {
        d += segment(uv-vec2(0.0,1.0),0)*b;
    }
    // segment 1
    if (n!=1 && n!=2 && n!=3 && n!=7){
        d += segment(uv-vec2(-0.5,0.5),1);
    } else {
        d += segment(uv-vec2(-0.5,0.5),1)*b;
    }
    // segment 2
    if (n!=5 && n!=6){ 
        d += segment(uv-vec2(0.5),1);
    } else {
        d += segment(uv-vec2(0.5),1)*b;
    }
    // segment 3
    if (n!=0 && n!=1 && n!=7){
        d += segment(uv,0);
    } else {
        d += segment(uv,0)*b;
    }
    // segment 4
    if(n==0 || n==2 || n==6 || n==8){
        d += segment(uv-vec2(-0.5),1);
    } else {
        d += segment(uv-vec2(-0.5),1)*b;
    }
    // segment 5
    if(n!=2){
        d += segment(uv-vec2(0.5,-0.5),1);
    } else {
        d += segment(uv-vec2(0.5,-0.5),1)*b;
    }
    // segment 6
    if(n!=1 && n!=4 && n!=7){
        d += segment(uv-vec2(0.0,-1.0),0);
    } else {
        d += segment(uv-vec2(0.0,-1.0),0)*b;
    }
    return d;
}

float box(vec2 uv){
    float d = abs(uv.x);
    
    d = smoothstep(0.05,0.045,d) * smoothstep(0.05,0.045,abs(uv.y));
    
    return d;
}

float colon(vec2 uv){
    
    float d = box(uv-vec2(0.0,0.13));
    
    d += box(uv-vec2(0.0,-0.13));
    
    return d;
    
}

float clock(vec2 uv){
    float d = 0.0;
    float time = date.w;
    
    float hour = floor(time/3600.0);
    float minute = floor((time - hour*3600.0)/60.0);
    float second = time - hour*3600.0 - minute*60.0;
        
    d += digit(uv-vec2(-1.55,0.0),int(floor(hour/10.0)));
    d += digit(uv-vec2(-1.0,0.0),int(floor(mod(hour,10.0))));
    
    d += colon(uv-vec2(-0.65,0.0));
    
    d += digit(uv-vec2(-0.3,0.0),int(floor(minute/10.0)));
    d += digit(uv-vec2(0.25,0.0),int(floor(mod(minute,10.0))));
    
    d+= colon(uv-vec2(0.6,0.0));
    
    d += digit(uv-vec2(0.95,0.0),int(floor(second/10.0)));
    d += digit(uv-vec2(1.5,0),int(floor(mod(second,10.0))));    
    
    return d;
}

void main(void)
{
    // Normalized pixel coordinates and adjust aspect ratio
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    
    uv *= 2.5; 
    
    float d = clock(uv);
    
    vec3 col = vec3(0.0,d,0.0);

    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
