#version 420

// original https://www.shadertoy.com/view/WsGGzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All the distance functions from:http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)
#define hash(h) fract(sin(h) * 43758.5453123)
#define PI 3.141592653589793

float sdBox( vec3 p, vec3 b, float r )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))-r
         + min(max(d.x,max(d.y,d.z)),0.0);
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

vec4 combine(vec4 val1, vec4 val2 ){
    if ( val1.w < val2.w ) {
        return val1;
    }
    return val2;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec4 map(vec3 p){
    vec3 pref = p;
    vec2 uv = p.xy;
    vec2 uvRef = uv;
    
    // body
    vec3 bodyPos = vec3(0.0,-0.2,0.0);
    float body1 = length(p+bodyPos+vec3(0.0,-0.2,0.0))-0.99;
    float body1_2 = sdEllipsoid(p+bodyPos+vec3(0.0,0.0,-0.7), vec3(0.55,0.3+sin(time)*0.15,0.5));
    body1 = opSmoothSubtraction(body1_2,body1,0.3);
    float body2 = sdBox(p+bodyPos+vec3(0.0,0.9,0.0), vec3(0.45,0.1,0.3),0.7);
    float bdres = opSmoothUnion(body1,body2,0.5);
    
    // eye ball
    float heyeball = length(p+bodyPos+vec3(0.0,-0.2,0.05))-0.92;
    float eyemoveX = sin(time)*0.1;
    float heyecold = length(uvRef+vec2(eyemoveX,-0.35))-0.35;
    vec3 heyecol = mix( vec3(1.0), vec3(0.0), 1.0-smoothstep(0.01,0.015,heyecold) );
    heyecold = length(uvRef+vec2(eyemoveX,-0.35))-0.27;
    heyecol = mix( heyecol, vec3(0.5,0.3,0.1), 1.0-smoothstep(0.01,0.015,heyecold) );
    heyecold = length(uvRef+vec2(eyemoveX,-0.35))-0.2;
    heyecol = mix( heyecol, vec3(0.7,0.5,0.1), 1.0-smoothstep(0.01,0.015,heyecold) );
    heyecold = length(uvRef+vec2(eyemoveX,-0.35))-0.12;
    heyecol = mix( heyecol, vec3(0.0), 1.0-smoothstep(0.01,0.015,heyecold) );
    
    // body eyeball
    p.x = abs(p.x);
    p.x -= 0.65;
    uvRef.x = abs(uvRef.x);
    uvRef.x -= 0.1;
    vec3 beyep = p+bodyPos+vec3(0.0,0.6,-0.85);
    float beyeball = length(beyep)-0.17;
    p = pref;
    
    eyemoveX = sin(time*2.0)*-0.05;
    float beyecold = length(uvRef+vec2(-0.56+eyemoveX,0.33))-0.06;
    vec3 beyecol = mix( vec3(1.0), vec3(0.0), 1.0-smoothstep(0.01,0.015,beyecold) );
    uvRef = uv;
    
    // eyelid
    p.x = abs(p.x);
    p.x -= 0.65;
    vec3 eyelidp = p+bodyPos+vec3(0.0,0.6,-0.85);
    float eyelid = length(eyelidp)-0.18;
    float eyelidMask = sdBox((eyelidp+vec3(0.0,0.37,0.0))*matRotateX(radians(25.0)), vec3(0.35),0.001);
    float eyelidres = max(-eyelidMask,eyelid);
    p = pref;
    
    // mouth and teeth
    vec3 mouthp = p+bodyPos+vec3(0.0,0.8,-0.95);
    float mouth = sqrt(mouthp.x*mouthp.x+(mouthp.y*mouthp.y*8.5)+(mouthp.z*mouthp.z*0.1))-0.15;
    
    vec3 teethp = p+bodyPos+vec3(0.0,0.76,-0.95);
    float teeth = sdBox(teethp, vec3(0.05,0.025,0.05),0.001);
    
    // legs and arms
    p.x = abs(p.x);
    p.x -= 0.5;
    vec3 legp = p+bodyPos+vec3(0.0,2.7,0.1);
    float leg = sdCapsule(legp,vec3(0.0,0.0,0.0),vec3(0.0,1.0,0.0),0.15);
    bdres = opSmoothUnion(bdres,leg,0.5);
    p = pref;
    
    p.x = abs(p.x);
    p.x -= 0.7;
    vec3 armp = p+bodyPos+vec3(0.0,2.2,-0.5);
    float arm = sdCapsule(armp,vec3(sin(time*6.0)*0.2,0.0,0.0),vec3(0.1,0.8,0.0),0.1);
    bdres = opSmoothUnion(bdres,arm,0.3);
    p = pref;
    
    // tail
    vec3 tailp = p+bodyPos+vec3(0.0,2.0,1.1);
    vec3 tailp2 = p+bodyPos+vec3(0.0,2.3,2.3);
    float tail = sdCapsule(tailp,vec3(0.0,-0.3,-0.2),vec3(0.0,0.9,0.0),0.3);
    float tail2 = sqrt(tailp2.x*tailp2.x+(tailp2.y*tailp2.y*1.5)+(tailp2.z*tailp2.z*0.5))-0.65;
    tail = opSmoothUnion(tail,tail2,0.6);
    
    
    
    vec4 _body = vec4(vec3(0.9,0.62,0.65),max(bdres,-mouth));
    vec4 _heyeball = vec4(heyecol,heyeball);
    vec4 _beyeball = vec4(beyecol,beyeball);
    vec4 _eyelid = vec4(vec3(0.9,0.62,0.65),eyelidres);
    vec4 _teeth = vec4(vec3(1.0),teeth);
    vec4 _tail = vec4(mix(vec3(0.9,0.62,0.65),vec3(-2.99,-2.92,-2.55),(tailp.z*0.1)),tail);
    vec4 _floor = vec4(vec3(1.0),p.y+2.6);
    
    return combine(combine(combine(combine(combine(combine(_body,_heyeball),_beyeball),_eyelid),_teeth),_tail),_floor);
}

vec3 normalMap(vec3 p){
    float d = 0.0001;
    return normalize(vec3(
        map(p + vec3(  d, 0.0, 0.0)).w - map(p + vec3( -d, 0.0, 0.0)).w,
        map(p + vec3(0.0,   d, 0.0)).w - map(p + vec3(0.0,  -d, 0.0)).w,
        map(p + vec3(0.0, 0.0,   d)).w - map(p + vec3(0.0, 0.0,  -d)).w
    ));
}

float shadowMap(vec3 ro, vec3 rd){
    float h = 0.0;
    float c = 0.001;
    float r = 1.0;
    float shadow = 0.5;
    for(float t = 0.0; t < 30.0; t++){
        h = map(ro + rd * c).w;
        if(h < 0.001){
            return shadow;
        }
        r = min(r, h * 16.0 / c);
        c += h;
    }
    return 1.0 - shadow + r * shadow;
}

// from simon green and others
float ambientOcclusion(vec3 p, vec3 n)
{
    const int steps = 4;
    const float delta = 0.15;

    float a = 0.0;
    float weight = 4.;
    for(int i=1; i<=steps; i++) {
        float d = (float(i) / float(steps)) * delta; 
        a += weight*(d - map(p + n*d).w);
        weight *= 0.5;
    }
    return clamp(1.0 - a, 0.0, 1.0);
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec2 uv = p;
    
    float time = time*2.0;
    
    vec3 ro = vec3( 3.5*cos(0.1*time + 6.0), 0.0, -0.5+5.5*sin(0.1*time + 6.0) );
    vec3 ta = vec3( 0.0, -0.4, -0.7 );
    mat3 ca = setCamera( ro, ta, 0.0 );
    float zoom = 1.5;
    vec3 rd = ca * normalize( vec3(p.xy,zoom) );
    
    float t, dist;
    float lastDistEval = 1e10;
    float edge = 0.0;
    t = 0.0;
    vec3 distPos = ro+rd;
    vec4 distCl = vec4(0.0);
    for(int i = 0; i < 64; i++){
        distCl = map(distPos);
        dist = distCl.w;
        t += dist;
        distPos = ro+rd*t;
        
        if (dist < lastDistEval) lastDistEval = dist;
        if(dist < 0.01 || dist > 60.0) break;
    }

    vec3 color;
    float shadow = 1.0;
    if(dist < 1.0){
        // lighting
        vec3 lightDir = vec3(0.0, 1.0, 0.0);
        vec3 light = normalize(lightDir + vec3(0.5, 0.0, 0.9));
        vec3 normal = normalMap(distPos);

        // difuse color
        float diffuse = clamp(dot(light, normal), 0.6, 1.0);
        float lambert = max(.0, dot( normal, light));
        
        // ambient occlusion
        float ao = ambientOcclusion(distPos,normal);
        
        // shadow
        shadow = shadowMap(distPos + normal * 0.001, light);

        // result
        color += vec3(lambert);
        color = ao*diffuse*(distCl.xyz+(.1-length(p.xy)/3.))*vec3(1.0, 1.0, 1.0);
        
    }else{
        color =.84*max(mix(vec3(0.9,0.9,0.9)+(.1-length(p.xy)/3.),vec3(1),.1),0.);
    }

    // rendering result
    float brightness = 1.5;
    vec3 dst = (color * max(0.8, shadow))*brightness;
    
    glFragColor = vec4(dst, 1.0);
}
