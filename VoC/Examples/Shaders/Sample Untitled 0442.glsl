#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 displayPos;
vec3 col=vec3(0);

#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))
const float PI= acos(-1.);

float sdSphere(vec3 p,float r){
    return length(p)-r;
}
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))+ min(max(d.x,max(d.y,d.z)),0.0);
}

vec3 rep(vec3 p,vec3 span){
    return mod(p,span)-span/2.;
}
float distFunc(vec3 pos){
    //float t=PI/6.;
    //pos.xy*=mat2(cos(2.*t),sin(2.*t),sin(2.*t),-cos(2.*t));
    float t=PI/2.*time*4.0;
    //pos.xy*=rot(t);
    int j=0;
    j=int((length(displayPos.xy))/(0.1))+1;
    pos.xy*=rot(t/float(j));
    col+=vec3(0.4,0.8,0.9)/100.*(pow(float(j),1.0));
    float d;
    d=sdSphere(rep(pos,vec3(10.)),3.);
    return d;
}

float distFunc2(vec3 pos){
    float d;
    //pos.xy*=rot(time*1.);
    int j=int((length(pos.xy))/40.)+1;
    pos.xy*=rot(PI/20.*time*float(j));
    d=sdBox(rep(pos,vec3(17,17,10)),vec3(3));
    
    return d;
}

void main( void ) {
    vec2 p = ( gl_FragCoord.xy * 2. - resolution.xy ) / min(resolution.x, resolution.y);
    displayPos=p;

    vec3 cameraPos = vec3(0., 0., -10.+time*5.);
    float screenZ = 5.;
    vec3 rayDirection = normalize(vec3(p, screenZ));
    
    float depth = 0.0;
    
    const int rayCnt=200;
    for (int i = 0; i < rayCnt; i++) {
        vec3 rayPos = cameraPos*2. + rayDirection * depth;
        float dist = distFunc(rayPos);
        if(dist<0.0001){
            col*=vec3(float(i)/float(rayCnt))/10.;//+ step(0.97,sin(rayPos.z/80.+time*3.));
            break;
        }
        depth += dist;
    }
    depth = 0.0;
    float hit=0.2;
    vec3 col2=vec3(0);
    for (int i = 0; i < rayCnt; i++) {
        vec3 rayPos = cameraPos + rayDirection * depth;
        float dist = distFunc2(rayPos);
        if(dist<0.0001){
            col2=vec3(0.2,0.8,0.95)*vec3(float(i)/float(rayCnt))- (col*step(0.97,sin(rayPos.z/80.+time*3.)));
            hit=1.;
            break;
        }
        depth += dist;
    }

    col=col;
    glFragColor = vec4(col, 1.0);
}
