#version 420

// original https://www.shadertoy.com/view/tllcRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

float random3 (in vec3 _st) {
    return fract(sin(dot(_st,
                         vec3(12.9898,78.233,123.24647)))*
      43758.5453123);
}

vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

float noise3 (in vec3 _st) {
    vec3 i = floor(_st);
    vec3 fr = fract(_st);

    // Four corners in 2D of a tile
    float a = random3(i);
    float b = random3(i + vec3(1.0, 0.0, 0.0));
    float c = random3(i + vec3(0.0, 1.0, 0.0));
    float d = random3(i + vec3(1.0, 1.0, 0.0));
    
    float e = random3(i + vec3(0.0, 0.0, 1.0));
    float f = random3(i + vec3(1.0, 0.0, 1.0));
    float g = random3(i + vec3(0.0, 1.0, 1.0));
    float h = random3(i + vec3(1.0, 1.0, 1.0));

    vec3 u = fr * fr * (3.0 - 2.0 * fr);
    
    float bf = mix(a,b,u.x);
    float bb = mix(c,d,u.x);
    
    float bot = mix(bf,bb,u.y);
    
    float tf = mix(e,f,u.x);
    float tb = mix(g,h,u.x);
    
    float top = mix(tf,tb,u.y); 

    return mix(bot,top,u.z);
}

#define NUM_OCTAVES 2

float fbm3 ( in vec3 _st) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100.0);
    float offset = 0.;
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        //v += a * sin((_st.y + _st.x+ _st.y)*10.)*1.5;
        offset += a*2.5;
        v += a * noise3(_st)*2.5;
        _st = _st * 2. + shift;
        a *= 0.5;
    }
    return v/offset;
}

float fbmN(vec3 _st, int n){
    float v = 0.;
    for (int i = 0;i<4;i++){
        if(i>=n) break;
        v= fbm3(_st + v*4.);
    }
    
    return v;
}

float map(vec3 pos){
 return length(pos) - 0.25;   
}

void main(void)
{
    mat4 rot = rotationMatrix(vec3(1.,1.,1.),-time/2.);
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    vec3 pos = (rot*vec4(vec3(0.0,0.0,1.0),1.)).xyz;
    
    vec3 pd = (rot*vec4(normalize(vec3(uv,-1.5)),1.)).xyz;
    
    vec3 col = vec3(0.0);
    float t = 0.0;
    float l = 0.;
    float fbm =0.;
    for(int i = 0; i<255; i++){
        vec3 p = pos + t*pd;       
        l = map(p);
        float fbmTest = fbmN(p*10.,1);
        //float fbmTest = noise3(p*10.);
        //float fbmTest = random3(p*10.);
            
        if((l<0.0002)){
            if(fbmTest >0.55){
                 break;
            }else{
             t+=0.002;   
            }
        }else{
        t += l;
        }
        
    }
    
    float plen = 0.;
    
    if (l< 0.0002){
    vec3 p = pos + t*pd;    
    fbm = fbmN(p*10.,1);
    //fbm = noise3(p*10.);
    //fbm = random3(p*10.);
    plen = length(p)/0.25;
    fbm *= fbm * (3.0 - 2.0 * fbm)*plen;
    }
    float inCircle = smoothstep(0.02,-0.,l);
    col = hsl2rgb(vec3(fbm*0.05+0.5,0.7,plen))*inCircle;
    glFragColor = vec4(col,1.);
}
