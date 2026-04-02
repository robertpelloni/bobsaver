#version 420

// original https://www.shadertoy.com/view/stcXzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p.x)-s.x,abs(p.y)-s.y)

float hash(vec2 p){
    vec2 rand = fract(sin(p*123.456)*567.89);
    rand += dot(rand,rand*34.56);
    return fract(rand.x*rand.y);
}

float starLayer(vec2 p){
    p.x += time*0.1;
    p*=12.0;
    vec2 uv = fract(p)-0.5;
    vec2 id = floor(p);
    float n = hash(id);
    
    vec2 size = vec2(0.0);
    float x = 0.0;
    if(n<0.1){
        size = vec2(0.025,0.2);
        uv.x-=0.2;
        uv.y-=0.2;
    } else if(n>=0.1 && n<0.4){
        size = vec2(0.02,0.15);
        uv.x+=0.3;
        uv.y+=0.2;
    }
    return min(B(uv,size),B(uv,vec2(size.y,size.x)));
}

float buildingWindowBase(vec2 p, float scale){
    p*=scale;
    vec2 uv = fract(p)-0.5;
    vec2 id = floor(p);
    vec2 size = vec2(0.25);
    return B(uv,size);
}

float buildingWindow(vec2 p, float scale){
    p*=scale;
    vec2 uv = fract(p)-0.5;
    vec2 id = floor(p);
    float n = hash(id);
    
    vec2 size = vec2(0.0);
    if(n<0.5){
        size = vec2(0.25);
    }
    return B(uv,size);
}

vec3 buildingMaterial(vec2 p, vec3 col, float scale){
    float d = buildingWindowBase(p,scale);
    col = mix(col,vec3(0.3),S(d,0.0));
    d = buildingWindow(p,scale);
    col = mix(col,vec3(0.8),S(d,0.0));
    return col;
}

float birds(vec2 p){
    p.x+=time*0.2;
    p.x = mod(p.x,0.8)-0.4;
    p.y-=0.45;
    float d = B(p,vec2(0.04,0.006));
    p.x+=0.01;
    p.y-=0.01+sin(time*5.0)*0.006;
    float d2 = B(p,vec2(0.02,0.006));
    return min(d,d2);
}

float cloud(vec2 p){
    float d = B(p,vec2(0.06,0.003));
    p.y+=0.011;
    d = min(B(p,vec2(0.1,0.003)),d);
    p.y+=0.011;
    d = min(B(p,vec2(0.28,0.003)),d);
    p.y+=0.011;
    p.x = abs(p.x);
    p.x-=0.13;
    d = min(B(p,vec2(0.09,0.003)),d);
    p.y+=0.011;
    d = min(B(p,vec2(0.05,0.003)),d);
    return d;
}

vec3 car(vec2 p, vec3 col){
    p*=7.0;
    vec2 prevP = p;
    
    p = prevP;
    p.y+=0.13;
    p.y*=7.0;
    float d = length(p)-0.4;
    col = mix(col,vec3(0.3),S(d,-0.2));    
    
    p = prevP;
    d = B(p,vec2(0.3,0.08));
    float a = radians(45.);
    p = abs(p);
    p-=vec2(0.3,0.05);
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    
    p = prevP;
    p.x = abs(p.x)-0.15;
    p.y+=0.05;
    d = max(-(length(p)-0.09),d);    
    
    col = mix(col,vec3(0.7,0.6,0.1),S(d,0.0));
    
    p = prevP;
    p.y-=0.16;
    d = B(p,vec2(0.19,0.08));
    a = radians(20.);
    p.x = abs(p.x);
    p.x-=0.14;
    p.y-=0.05;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    col = mix(col,vec3(0.7,0.6,0.1),S(d,0.0));
    
    p = prevP;
    p.y-=0.16;
    d = B(p,vec2(0.15,0.06));
    a = radians(20.);
    p.x = abs(p.x);
    p.x-=0.11;
    p.y-=0.06;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    p = prevP;
    d = max(-(abs(p.x)-0.012),d);
    col = mix(col,vec3(0.6,0.8,0.9),S(d,0.0));
    
    p = prevP;
    p.x = abs(p.x)-0.15;
    p.y+=0.05;
    d = length(p)-0.08;
    col = mix(col,vec3(0.),S(d,0.0));
    d = length(p)-0.06;
    col = mix(col,vec3(0.7),S(d,0.0));
    
    return col;
}

vec3 missile(vec2 p, vec3 col, vec3 col2){
    vec2 prevP = p;
    p = prevP;
    p -= vec2(0.06,-0.02);
    float d = B(p,vec2(0.07,0.015));
    d = min(length(p-vec2(-0.07,0.0))-0.015,d);
    
    p.x -= 0.03;
    p.y = abs(p.y);
    p.y-=0.02;
    float d2 = B(p,vec2(0.03,0.02));
    float a = radians(-40.0);
    d2 = max(-dot(p,vec2(cos(a),sin(a))),d2);
    d = min(d2,d);
    col = mix(col,col2,S(d,0.0));
    return col;
}

vec3 chopper(vec2 p, vec3 col){
    p*=Rot(radians(-10.0));
    p*=1.7;
    p.y+=sin(time*3.0)*0.02;
    vec2 prevP = p;
    float d = B(p,vec2(0.22,0.1));
    float a = radians(-70.);
    p.y-=0.09;
    d = max(-dot(p,vec2(cos(a),sin(a))),d);
    p = prevP;
    a = radians(70.);
    p.y+=0.13;
    d = max(-dot(p,vec2(cos(a),sin(a))),d);
    p = prevP;
    a = radians(45.);
    p.x-=0.26;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    p = prevP;
    a = radians(-50.);
    p.x-=0.3;
    p.y-=0.06;
    d = max(dot(p,vec2(cos(a),sin(a))),d);
    
    p = prevP;
    p.x-=0.35;
    p.y-=0.015;
    d = min(B(p,vec2(0.15,0.025)),d);
    
    p = prevP;
    p.y-=0.015;
    p.y = abs(p.y);
    p.x-=0.49;
    p.y-=0.06;
    
    p*=Rot(radians(10.0));
    a = radians(-10.);
    
    d = min(max(-dot(p-vec2(-0.01,0.0),vec2(cos(a),sin(a))),B(p,vec2(0.02,0.05))),d);
    
    col = mix(col,vec3(0.3,0.5,0.3),S(d,0.0));
    
    p = prevP;
    p.x+=0.08;
    p.y-=0.05;
    d = B(p,vec2(0.1,0.05));
    a = radians(-70.);
    d = max(-dot(p,vec2(cos(a),sin(a))),d);
    
    a = radians(-70.);
    d = max(dot(p-vec2(0.00,-0.05),vec2(cos(a),sin(a))),d);
    
    col = mix(col,vec3(0.6,0.8,0.9),S(d,0.0));
    
    p = prevP;
    p.x = abs(p.x)-0.06;
    p.y+=0.13;
    d = B(p,vec2(0.006,0.03));
    p.y+=0.03;
    d = min(B(p,vec2(0.07,0.006)),d);
    col = mix(col,vec3(0.3,0.5,0.5),S(d,0.0));
    
    p = prevP;
    p.x-=0.1;
    p.y-=0.14;
    d = B(p,vec2(0.01,0.05));
    p.y-=0.02;
    d = min(B(p,vec2(0.3+sin(time*10.0)*0.25,0.01)),d);
    
    col = mix(col,vec3(0.3,0.5,0.5),S(d,0.0));
    
    p = prevP;
    col = missile(p-vec2(0.01,-0.01),col,vec3(0.2,0.4,0.4)*0.3);
    col = missile(p,col,vec3(0.2,0.4,0.4));
    
    
    return col;
}

vec3 streetLight(vec2 p, vec3 col){
    p*=2.0;
    vec2 prevP = p;
    float d = B(p,vec2(0.005,0.1));
    col = mix(col,vec3(0.7,0.3,0.2),S(d,0.0));
    
    p*=Rot(radians(45.));
    p.x+=0.068;
    p.y-=0.115;
    d = B(p,vec2(0.005,0.05));
    col = mix(col,vec3(0.7,0.3,0.2),S(d,0.0));
    
    p = prevP;
    
    p*=Rot(radians(45.));
    p.x+=0.058;
    p.y-=0.115;
    d = B(p,vec2(0.005,0.025));
    col = mix(col,vec3(1.0),S(d,0.0));
    
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    
    vec3 col = mix(vec3(0.5,0.3,0.7),vec3(0.3,0.3,0.5),uv.y+0.3);
    
    float t = time;
    
    // The following code should be `sqrt(8^2-x^2)`, but it does not work for me, so I used the normal circle distance function.
    float d = length(uv-vec2(0.0,-0.15))-0.6;
    uv.y-=time*0.05;
    uv.y = mod(uv.y,0.05)-0.025;
    d = max(-B(uv,vec2(10.0,0.01)),d);
    col = mix(col,mix(vec3(0.7,0.5,0.6),vec3(0.7,0.1,0.5),prevUV.y+0.2),S(d,0.0));    
    
    // star
    uv = prevUV;
    d = starLayer(uv);
    col = mix(col,vec3(0.6,0.4,0.5),S(max(-uv.y+0.25,d),0.0));  
    
    // clouds
    uv = prevUV;
    uv.x-=time*0.05;
    uv.x = mod(uv.x,1.6)-0.8;
    uv.y-=0.45;
    d = cloud(uv);
    col = mix(col,vec3(0.6,0.2,0.3),S(d,0.0)); 
    
    // birds
    uv = prevUV;
    d = birds(uv);
    col = mix(col,vec3(0.0),S(d,0.0)); 
    
    // buildings1
    uv*=6.0;
    d = -0.7+1.5*sin(floor((uv.x*2.5)+t)*4321.);
    uv.y += d;
    col = mix(col,vec3(0.15),S(uv.y,0.0));
    
    // buildings2
    uv = prevUV;
    uv*=6.0;
    d = -0.7+1.*sin(floor((uv.x*1.5)+(t*1.5))*2121.);
    uv.y += d;
    uv.x+=time+0.22;
    col = mix(col,buildingMaterial(uv,vec3(0.2),8.5),S(uv.y,0.0));
    
    // buildings3
    uv = prevUV;
    uv.x+=time*0.3;
    uv*=1.2;
    uv.y+=0.1;
    uv.x = mod(uv.x,0.6)-0.3;
    d = B(uv,vec2(0.1,0.16));
    float a = radians(30.0);
    uv.x = abs(uv.x);
    uv.y-=0.3;
    d = max(dot(uv,vec2(cos(a),sin(a))),d);
    col = mix(col,buildingMaterial(uv,vec3(0.05),60.),S(d,0.0));
    uv.x = abs(uv.x)-0.05;
    uv.y+=0.13;
    d = B(uv,vec2(0.01,0.01));
    col = mix(col,vec3(0.5,0.0,0.0),S(d,0.0));

    uv = prevUV;
    uv.x+=time*0.3;
    uv*=1.2;
    uv.y+=0.1;
    uv.x-=0.3;
    uv.x = mod(uv.x,0.6)-0.3;
    d = B(uv,vec2(0.1,0.22));
    uv.x = abs(uv.x);
    uv.y-=0.36;
    d = max(dot(uv,vec2(cos(a),sin(a))),d);
    col = mix(col,buildingMaterial(uv,vec3(0.05),80.),S(d,0.0));
    
    
    // road
    uv = prevUV;
    col = mix(col,vec3(0.3),S(uv.y+0.2,0.0));
    col = mix(col,vec3(0.4),S(uv.y+0.25,0.0));
    col = mix(col,vec3(0.5),S(uv.y+0.45,0.0));
    
    uv.x+=time*0.3;
    uv.x = mod(uv.x,0.4)-0.2;
    uv.y+=0.34;
    d = B(uv,vec2(0.1,0.002));
    col = mix(col,vec3(1.0),S(d,0.0));
    
    // street rights
    uv = prevUV;
    uv.x+=time*0.28;
    uv.x = mod(uv.x,0.4)-0.2;
    uv.y+=0.18;
    col = streetLight(uv,col);
    
    // cars
    uv = prevUV;
    uv.x+=time*0.4;
    uv.x = mod(uv.x,0.15)-0.075;
    uv.y+=0.28;
    col = car(uv,col);
    
    uv = prevUV;
    uv.x-=time*0.2-0.075;
    uv.x = mod(uv.x,0.15)-0.075;
    uv.y+=0.4;
    col = car(uv,col);
    
    // street rights
    uv = prevUV;
    uv.x+=time*0.28;
    uv.x = mod(uv.x,0.4)-0.2;
    uv.y+=0.43;
    col = streetLight(uv,col);    
    
    // chopper
    uv = prevUV;
    uv.x+=time*0.6-0.6;
    uv.x = mod(uv.x,2.6)-1.3;
    uv.y-=0.2;
    col = chopper(uv,col);
    
    // test codes
    uv = prevUV;
    //col = streetLight(uv,col);
    
    // Output to screen
    //glFragColor = vec4(col,1.0);
    glFragColor = vec4(col, 1.0)+(hash(uv*time*0.1))*0.13;
}
