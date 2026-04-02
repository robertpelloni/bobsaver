#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rotateMat(x) mat2(cos(x),-sin(x),sin(x),cos(x))

vec3 light;

float sdSphere(vec3 p,float r){
    return length(p)-r;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0)) - r + min(max(d.x,max(d.y,d.z)),0.0);
}

vec3 rep(vec3 p,vec3 span){
    return mod(p,span)-span/2.;
}

float mixStep(float x){
    return clamp(sin(x)*10.,-1.,1.);
}

float distanceFunction(vec3 pos){
    float d;
    d=mix(sdSphere(rep(pos,vec3(5,20,5)),2.),sdRoundBox(rep(pos,vec3(5,20,5)),vec3(2.),0.),0.5+mixStep(time)*0.5);
    vec3 boxPos=pos;
    boxPos.xy*=rotateMat(time);
    boxPos.xz*=rotateMat(time*3.);
    d=min(d,sdRoundBox(boxPos,vec3(1),0.));
    //d=min(d,sdSphere(pos-light,1.));
    return d;
}

vec3 getNormal(vec3 p){
    float d = 0.0001;
    return normalize(vec3(
        distanceFunction(p + vec3(  d, 0.0, 0.0)) - distanceFunction(p + vec3( -d, 0.0, 0.0)),
        distanceFunction(p + vec3(0.0,   d, 0.0)) - distanceFunction(p + vec3(0.0,  -d, 0.0)),
        distanceFunction(p + vec3(0.0, 0.0,   d)) - distanceFunction(p + vec3(0.0, 0.0,  -d))
    ));
}

void main( void ) {
    vec2 p = ( gl_FragCoord.xy * 2. - resolution.xy ) / min(resolution.x, resolution.y);

    vec3 cameraPos = vec3(0.,0., -10.);
    float screenZ = 1.;
    vec3 rayDirection = normalize(vec3(p, screenZ));
    
    light=vec3(sin(time*2.)*10.,0,0);

    
    float depth = 0.0;

    vec3 col = vec3(0.0);
    bool hit=false;
    const int rayMax=200;
    
    for (int i = 0; i < rayMax; i++) {
        vec3 rayPos = cameraPos + rayDirection * depth;
        float dist = distanceFunction(rayPos);

        if (dist < 0.0001) {
            col = (1.-float(i)/100.)*vec3(0.4);
        float l=length(light-rayPos);
        col+=(mix(vec3(4,2,2),vec3(2,5,5),mixStep(time)))*2./l*(dot(normalize(light-rayPos),getNormal(rayPos)));
        hit=true;
            break;
        }

        depth += dist;
    }
    if(!hit){
        
    }
    glFragColor = vec4(col, 1.0);
    
}
