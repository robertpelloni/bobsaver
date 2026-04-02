#version 420

// original https://www.shadertoy.com/view/wttyR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define BASE_COLOR vec3(0.3,0.6,0.3)

float SimpleVesicaDistance(vec2 p, float r, float d) {
    p.x = abs(p.x);
    p.x+=d;
    return length(p)-r;
}

// https://www.youtube.com/watch?v=PMltMdi1Wzg&t=367s
float sdSegment(vec2 p, float L, float R) {
    p.y -= min(L,max(0.0,p.y));
    return length(p)-R;
}

float layer0(vec2 p){
    vec2 prevP = p;
    float r = 0.001;
    p = abs(p);
    p -= vec2(0.05);
    float d = SimpleVesicaDistance(p*Rot(radians(45.0)),0.12,0.09);
    p = prevP;
    
    p*= Rot(radians(45.0));
    p = abs(p);
    p -= vec2(0.05);
    float d2 = SimpleVesicaDistance(p*Rot(radians(45.0)),0.12,0.09);
    
    d = min(abs(d)-r,abs(d2)-r);
    
    for(float i = 0.0;i<4.0; i++) {
        p = prevP;
        p*= Rot(radians(22.5*i));
        p = abs(p);
        p -= vec2(0.115);
        d2 = SimpleVesicaDistance(p*Rot(radians(45.0)),0.12,0.09);
        d = min(d,abs(d2)-r); 
    }
    
    for(float i = 0.0;i<8.0; i++) {
        p = prevP;
        p*= Rot(radians(11.25*i));
        p = abs(p);
        p -= vec2(0.167);
        d2 = SimpleVesicaDistance(p*Rot(radians(45.0)),0.12,0.099);
        d = min(d,abs(d2)-r); 
    }
    
    p = prevP;
    d2 = length(p)-0.32;
    d = min(d,abs(d2)-r);
    d2 = length(p)-0.45;
    d = min(d,abs(d2)-r);    
    
    return d;
}

float layer1(vec2 p, float d){
    vec2 prevP = p;
    float r = 0.001;
    float d2 = 0.0;
    for(float i = 0.0;i<16.0; i++) {
        p = prevP;
        p*= Rot(radians(5.625*i));
        p = abs(p);
        p -= vec2(0.215);
        d2 = SimpleVesicaDistance(p*Rot(radians(45.0)),0.12,0.105);
        d = min(d,abs(d2)-r); 
    
        p = prevP;
        p*= Rot(radians(5.625*i));
        p = abs(p);
        p -= vec2(0.315);
        d2 = SimpleVesicaDistance(p*Rot(radians(45.0)),0.12,0.105);
        d = min(d,abs(d2)-r);
        p = prevP;
        p*= Rot(radians(5.625*i));
        p = abs(p);
        p -= vec2(0.28);
        d2 = length(p)-0.03;
        d = min(d,abs(d2)-r);
    }
    
    return d;
}

float layer2(vec2 p, float d, float scale, float scale2, float numline){
    vec2 prevP = p;
    float r = 0.001;
    float d2 = 1.0;
    
    float t = time *0.1;

    for(float i = 0.0; i<numline; i++){
        float targetScale1 = 0.3-(i*scale2);
        float targetScale2 = (0.2-(i*scale2));
        float targetScale3 = (0.17-(i*scale2));
        
        if(i>=4.0) {
            targetScale1 = (0.3-(i*0.01))*abs(sin(t*i))+0.1*(i*0.1);
            targetScale2 = (0.2-(i*0.01))*abs(sin(t*i))+0.05*(i*0.1);
            targetScale3 = (0.17-(i*0.01))*abs(sin(t*i))+0.03*(i*0.1);
        }        
        
        p = prevP;
        p.x = abs(p.x);
        p.x -= 0.5*scale;
        d2 = SimpleVesicaDistance(p*Rot(radians(90.0)),targetScale1*scale,0.2*scale);

        d = min(d,abs(d2)-r*1.0);

        p = prevP;
        p = abs(p);
        p -= vec2(0.3)*scale;
        d2 = SimpleVesicaDistance(p*Rot(radians(45.0)),targetScale1*scale,0.2*scale);

        d = min(d,abs(d2)-r*1.0);    

        p = prevP;
        p.y = abs(p.y);
        p.y -= 0.4*scale;
        d2 = length(p)-targetScale2*scale;

        d = min(d,abs(d2)-r*1.0);

        p = prevP;
        p = abs(p);
        p -= vec2(0.35,0.15)*scale;
        d2 = length(p)-targetScale3*scale;

        d = min(d,abs(d2)-r*1.0); 
    }
    
    return d;
}

float VesicaShapeDistance(vec2 p) {
    float t = time*0.2;
    float d = layer2(p,1.0,1.0,0.02,6.0);
    d = max(-( length(p)-0.45),d);    
    
    float d2 = min(d,layer0(p*Rot(radians(-30.0*t))));
    float d3 = layer1(p*Rot(radians(30.0*t*0.5)),d2);
    return d3;
}

float VesicaShapeBackground(vec2 p) {
    vec2 prevP = p;
    float d = 1.0;
    p.x = abs(p.x);
    p.x -= 0.5;
    float d2 = SimpleVesicaDistance(p*Rot(radians(90.0)),0.3,0.2);

    d = min(d,d2);

    p = prevP;
    p = abs(p);
    p -= vec2(0.3);
    d2 = SimpleVesicaDistance(p*Rot(radians(45.0)),0.3,0.2);

    d = min(d,d2);    

    p = prevP;
    p.y = abs(p.y);
    p.y -= 0.4;
    d2 = length(p)-0.2;

    d = min(d,d2);

    p = prevP;
    p = abs(p);
    p -= vec2(0.35,0.15);
    d2 = length(p)-0.17;

    d = min(d,d2); 
    
    p = prevP;
    
    d2 = length(p)-0.45;
    d = min(d,d2); 
    
    return d;
}

float Background(vec2 p) {
    float t = time *0.3;
    p.x = mod(p.x,0.43)-0.215;
    p.y = mod(p.y,0.36)-0.18;
    
    vec2 prevP = p;
    vec2 prevP2 = p;
    
    float d = layer2(p,1.0,0.3,0.04,3.0);
    
    p*=Rot(radians(-30.0*t));
    prevP*=Rot(radians(-30.0*t));
    p*=2.5;
    prevP*=2.5;
    
    p = abs(p);
    p-=vec2(0.105,0.043);
    float h = mod(t*0.3,0.6);
    if(h>=0.2){
        h = 0.2-(h-0.2);
    }
    float d2 = sdSegment(p*Rot(radians(-52.0)),h,0.004);
    d = min(d,d2);
    
    p = prevP;
    p.x = abs(p.x);
    p.x -= 0.105;
    p.y += 0.042;
    d2 = sdSegment(p,(h/0.2)*0.085,0.004);
    d = min(d,d2);
    
    p = prevP2;
    p = abs(p);
    p-=vec2(0.105,0.043);
    d2 = sdSegment(p*Rot(radians(-52.0)),0.15,0.001);
    d = min(d,d2);
    
    p = prevP2;
    p.x = abs(p.x);
    p.x -= 0.105;
    p.y += 0.042;
    d2 = sdSegment(p,0.085,0.001);
    d = min(d,d2);
    
    return d;
}

float Background2(vec2 p) {
    float t = time *0.3;
    float thickness = 0.001;
    float r = 0.05;
    vec2 prevP = p;

    p.x+= 0.215;
    p.y+= 0.18;
    p.x = mod(p.x,0.43)-0.215;
    p.y = mod(p.y,0.36)-0.18;

    p*=Rot(radians(30.0*t*3.0));
    
    float d = length(p-vec2(0.0,r*0.5))-r;
    float d2 =  length(p-vec2(0.0,-r*0.5))-r;
    
    d = min(abs(d)-thickness,abs(d2)-thickness);
    
    p*=Rot(radians(90.0));
    d2 = length(p-vec2(0.0,r*0.5))-r;
    d = min(d,abs(d2)-thickness);
    d2 =  length(p-vec2(0.0,-r*0.5))-r;
    d = min(d,abs(d2)-thickness);
    
    p = prevP;
    
    p.x+= 0.215;
    p.y+= 0.18;
    p.x = mod(p.x,0.43)-0.215;
    p.y = mod(p.y,0.36)-0.18;
    p*=Rot(radians(45.0));
    p = abs(p);
    p -= vec2(0.083);
    d2 = SimpleVesicaDistance(p*Rot(radians(45.0)),0.045,0.03);    
    d = min(d,abs(d2)-thickness*1.2);
    
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    vec3 col = vec3(0.99,0.98,0.95);
    
    vec3 lineCol = vec3(132.0/255.0,153.0/255.0,141.0/255.0);
    
    uv.y+=time*0.1;
    uv*=1.3;
    float d = Background(uv);
    col = mix(col,lineCol,S(d,0.0));//0.9,0.6,0.5
    
    d = Background2(uv);
    col = mix(col,lineCol,S(d,0.0));
    
    uv = prevUV;
    uv*=1.17;
    
    d = VesicaShapeBackground(uv);
    col = mix(col,vec3(245.0/255.0,253.0/255.0,163.0/255.0)*1.45,S(d,-0.06));
    
    uv = prevUV;
    uv*=1.25;
    d = VesicaShapeDistance(uv);
    col = mix(col,vec3(140.0/255.0,152.0/255.0,171.0/255.0),S(d,0.0));
    
    glFragColor = vec4(col,1.0);
}
