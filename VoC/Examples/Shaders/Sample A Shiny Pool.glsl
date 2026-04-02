#version 420

// original https://www.shadertoy.com/view/Mlccz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

vec3 random3(vec3 st){
    st = vec3( dot(st,vec3(17.1,61.7,19.73)),
              dot(st,vec3(69.43,33.3,93.8)),
             dot(st,vec3(74.31,36.1,83.9)));
    return -1.0 + 2.0*fract(sin(st)*437581.5453123);
}

// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st,float travel) {
    st += vec2(0.,0.);
    vec3 i = floor(vec3(st,travel));
    vec3 f = fract(vec3(st,travel));
    

    vec3 u = smoothstep(0.,1.,f);

    float base00 = dot( random3(i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) );
    float base10 = dot( random3(i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) );
    float base01 = dot( random3(i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) );
    float base11 = dot( random3(i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) );
    float top00 = dot( random3(i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) );
    float top10 = dot( random3(i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) );
    float top01 = dot( random3(i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) );
    float top11 = dot( random3(i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) );
    float base = mix(mix(base00,base10,u.x),mix(base01,base11,u.x),u.y);
    float top = mix(mix(top00,top10,u.x),mix(top01,top11,u.x),u.y);
    return mix(base,top,u.z);
    
}

float bumpFunc(vec2 st){
    vec2 aspect = vec2(resolution.x/resolution.y,1.);
    float center = smoothstep(1.,0.,length(st));
    vec2 noisedist = vec2(noise((st+0.3)*2.,10.),noise((st+vec2(13.1238,11.8837))*2.,time*0.1));
    noisedist += vec2(noise((st)*8.,3.),noise((st+vec2(13.1238,11.8837))*8.,time*0.1+28.))*0.1;
    float noisevalue = noise((st+noisedist*0.07+vec2(0.,time*0.05)*5.),time*2.);
    noisevalue += noise((st+noisedist*0.35+vec2(0.,time*0.05))*25.,time*0.5)*0.25;
    noisevalue += noise(st*5.5,time*0.15)*0.15;
    return center*0.+smoothstep(-1.25,1.25,noisevalue);
}

//LIGHTING and BUMP section adapted from https://www.shadertoy.com/view/4l2XWK

vec3 bumpMap(vec3 st){
    vec3 sp = st;
    vec2 eps = vec2(4./resolution.y, 0.);
    float f = bumpFunc(sp.xy); // Sample value multiplied by the amplitude.
    float fx = bumpFunc(sp.xy-eps.xy); // Same for the nearby sample in the X-direction.
    float fy = bumpFunc(sp.xy-eps.yx); // Same for the nearby sample in the Y-direction.

    const float bumpFactor = 0.1;
    fx = (fx-f)/eps.x; // Change in X
    fy = (fy-f)/eps.x; // Change in Y.
    return vec3(fx,fy,0.)*bumpFactor;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
  

    // VECTOR SETUP - surface postion, ray origin, unit direction vector, and light postion.
    vec3 sp = vec3(uv, 0); // Surface position.
    vec3 rd = normalize(vec3(uv, 1.)); // Direction vector from the origin to the screen plane.
    vec3 lp = vec3(mouse*resolution.xy.xy/resolution.xy*2.-vec2(1.), -0.85); // Light position
    vec3 sn = vec3(0., 0., -1); // Plane normal. Z pointing toward the viewer.
    
    // Using the gradient vector, "vec3(fx, fy, 0)," to perturb the XY plane normal ",vec3(0, 0, -1)." 
    sn = normalize( sn + bumpMap(sp));           
   
    
    // LIGHTING
    // Determine the light direction vector, calculate its distance, then normalize it.
    vec3 ld = lp - sp;
    float lDist = max(length(ld), 0.001);
    ld /= lDist;  
    float atten = 1./(1.0 + lDist*lDist*0.05);

    // Diffuse value.
    float diff = max(dot(sn, ld), 0.);  
    // Specular highlighting.
    float spec = pow(max(dot( reflect(-ld, sn), -rd), 0.), 31.);
    
    //reflections
    vec3 ref = reflect( vec3(sp.xy,bumpFunc(sp.xy)*0.8), sn );
      float m = 2. * sqrt(pow( ref.x, 2. ) +
                pow( ref.y, 2. ) +
                pow( ref.z + 1., 2. ));
      vec2 tcx = ref.xy / m + .5;
    vec3 env_color = vec3(0.0);
    float grain = noise(uv.xy*10.,0.1);
    vec3 color = diff*0.35*vec3(0.65,0.8,0.8)+vec3(0.25,0.89,0.9)*spec*1.75+pow(env_color,vec3(2.9))*0.65+vec3(grain*0.1);
    glFragColor = vec4(color,1.);
    //glFragColor = vec4(vec3(bumpFunc(sp.xy)),1.);
}
