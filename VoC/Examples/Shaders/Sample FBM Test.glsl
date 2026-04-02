#version 420

// original https://www.shadertoy.com/view/XsKyz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI 6.28318530718
vec3 random3(vec3 st)
{
    st = vec3( dot(st,vec3(127.1,311.7,211.2)/20.),
                dot(st,vec3(269.5,183.3, 157.1)), dot(st,vec3(269.5,183.3, 17.1))  );
       return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}
float noise3D(vec3 st) 
{
    vec3 i = floor(st) ;
      vec3 f = fract(st);
        
    vec3 u = smoothstep(0.,1.,f);
    
    float valueNowxy01 =mix( mix( dot( random3(i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ),
                                  dot( random3(i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                        mix( dot( random3(i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ),
                                   dot( random3(i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y);
    float valueNowxy02 =mix( mix( dot( random3(i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ),
                                  dot( random3(i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                        mix( dot( random3(i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ),
                                   dot( random3(i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y);

    float toReturn = abs(mix(valueNowxy01, valueNowxy02, u.z));
    return pow(.2, toReturn) -0.4;;

}
mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float fbm(vec2 st){
    
    int n = 6;
    float toReturn = 0.;
    float frequencyIncrease = 2.9;
    float amplitudeDecrese = 0.5;
    float amplitude = 0.9;
    float frequency = 1.;
    
    for(int i = 0; i < n; i++){
        
        float det =  float(mod(float(i),2.)==0.);
        int signMul = (int(det)*2)-1;
        toReturn += amplitude*noise3D(vec3(st.xy *rotate2d(float(i/n))*frequency, time*0.1*amplitude));
        
        amplitude *= amplitudeDecrese ;
        
        frequency *= frequencyIncrease;
    }
    
    return toReturn;
    
    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 toCenter = vec2(0.5) - uv ;
    float dis = length(toCenter);
    float angle = (acos(toCenter.x*1.0/dis)/TWO_PI)*2. ;
    //vec2 st = vec2(angle , dis );
    vec2 st = uv;
    // Time varying pixel color
    float r1 = fbm( st);
    float r2 = fbm( st*rotate2d(1.14) + vec2(1412., 124.)+r1);
    float colt = fbm( st*rotate2d(0.213) +vec2(14122., 14.)+r2);
    // Output to screen
    vec3 finColor = mix(vec3(r1, r2, colt), vec3(0.121, pow(min(r1,r2),2.), 0.2), colt);
    finColor = mix(finColor, 
                   vec3(dot(finColor, vec3(0.91,abs(sin(time*0.2)),0.2)), dot(finColor, vec3(colt)), colt*r1), r2); 
    glFragColor = vec4(finColor,1.);
}
