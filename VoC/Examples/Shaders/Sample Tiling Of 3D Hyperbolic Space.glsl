#version 420

// original https://www.shadertoy.com/view/lddBD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//vec2 conj(in vec2 a){
//    return vec2(a.x, -a.y);
//}

//vec2 cmul(in vec2 a, in vec2 b){
//    return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
//}

//vec2 cdiv(in vec2 a, in vec2 b){
//    return vec2(a.x*b.x + a.y*b.y, a.y*b.x - a.x*b.y) / (b.x*b.x + b.y*b.y);   
//}

vec4 c2q(in vec2 a){
    return vec4(a.x, a.y, 0.0, 0.0);
}

vec4 qonj(in vec4 q){
    return vec4(q.x, -q.y, -q.z, -q.w);
}

vec4 qinv(in vec4 q){
     return qonj(q) / (q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w);
}

vec4 qmul(in vec4 p, in vec4 q){
    return vec4(p.x*q.x - p.y*q.y - p.z*q.z - p.w*q.w,
                p.x*q.y + p.y*q.x + p.z*q.w - p.w*q.z,
                p.x*q.z - p.y*q.w + p.z*q.x + p.w*q.y,
                p.x*q.w + p.y*q.z - p.z*q.y + p.w*q.x);
}

vec4 qdiv(in vec4 p, in vec4 q){
    return qmul(p, qinv(q));
}

vec4 qmob(in vec2[4] M, in vec4 z){ // see Ahlfors 1981 Mob tsfms p14
    vec4 a = c2q(M[0]);
    vec4 b = c2q(M[1]);
    vec4 c = c2q(M[2]);
    vec4 d = c2q(M[3]);
    return qdiv( qmul(a,z)+b, qmul(c,z)+d ); // if z.w = 0 then result.w = 0
}

const float sqrt3 = sqrt(3.0);
const vec2 w = vec2(0.5, 0.5*sqrt3);
const vec2 winv = vec2(0.5, -0.5*sqrt3);
const vec2 wphalf = vec2(0.5*sqrt3, 0.5);
const vec2 wpmhalf = vec2(0.5*sqrt3, -0.5);
const vec2 c0 = vec2(0.0,0.0);
const vec2 c1 = vec2(1.0,0.0);
const vec2 c2 = vec2(2.0,0.0);
const vec2 ci = vec2(0.0,1.0);

bool needt1(in vec4 q){  // q is wrong side of face of fund domain corresponding to transformation 1
    return q.x*(-0.5*sqrt3) + q.y*0.5 > 0.0;
}
bool needt1inv(in vec4 q){  // q is wrong side of face of fund domain corresponding to inv transformation 1
    vec4 center = c2q((c1 + winv)/3.0);
    vec4 qmc = q - center;
    return qmc.x*qmc.x + qmc.y*qmc.y + qmc.z*qmc.z < 1.0/3.0;
    //return length(q - center) < 1.0 / sqrt3;
}
bool needt2(in vec4 q){  // q is wrong side of face of fund domain corresponding to transformation 2
    return q.x*(-0.5*sqrt3) + q.y*(-0.5) > 0.0;
}
bool needt2inv(in vec4 q){  // q is wrong side of face of fund domain corresponding to inv transformation 2
    return (q.x-1.0)*(0.5*sqrt3) + q.y*(0.5) > 0.0;
}
bool needt3(in vec4 q){  // q is wrong side of face of fund domain corresponding to transformation 3
    return (q.x-1.0)*(0.5*sqrt3) + q.y*(-0.5) > 0.0;
}
bool needt3inv(in vec4 q){  // q is wrong side of face of fund domain corresponding to inv transformation 3
    vec4 center = c2q((c1 + w)/3.0);
    vec4 qmc = q - center;
    return qmc.x*qmc.x + qmc.y*qmc.y + qmc.z*qmc.z < 1.0/3.0;
    //return length(q - center) < 1.0 / sqrt3;
}

// vec2[4] t1 = [c1, winv, c1, c1]; //these dont compile
// vec2[4] t1inv = [c1, -winv, -c1, c1];
// vec2[4] t2 = [winv, c1, c0, winv];
// vec2[4] t2inv = [winv, -c1, -c0, winv];
// vec2[4] t3 = [w, -c1, c1, w - c2];
// vec2[4] t3inv = [w - c2, c1, -c1, w];

void main(void)
{
    vec2 t1[4];
    t1[0] = c1;
    t1[1] = -w;
    t1[2] = c1;
    t1[3] = winv;  // is this really the only way to assign values to the array??
    vec2 t1inv[4];
    t1inv[0] = winv;
    t1inv[1] = w;
    t1inv[2] = -c1;
    t1inv[3] = c1;
    vec2 t2[4];
    t2[0] = c1;
    t2[1] = w;
    t2[2] = c0;
    t2[3] = c1;
    vec2 t2inv[4];
    t2inv[0] = c1;
    t2inv[1] = -w;
    t2inv[2] = -c0;
    t2inv[3] = c1;
    vec2 t3[4];
    t3[0] = -winv;
    t3[1] = -w;
    t3[2] = w;
    t3[3] = -w - c1;
    vec2 t3inv[4];
    t3inv[0] = -w - c1;
    t3inv[1] = w;
    t3inv[2] = -w;
    t3inv[3] = -winv; //all these should have det 1 now
    
    vec2 p = 1.05*(-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;
    vec4 q = vec4(p, 0.01+0.3+0.3*cos(time), 0.0);

    bool inside_fund_dom = false;
    for(int i=0;i<128;i++){
        if (needt1(q)){
            q = qmob(t1, q);
        }
        else if (needt2(q)){
            q = qmob(t2, q);
        }
        else if (needt3(q)){
            q = qmob(t3, q);
        }
        else if (needt2inv(q)){
            q = qmob(t2inv, q);
        }
        else if (needt1inv(q)){
            q = qmob(t1inv, q);
        }
        else if (needt3inv(q)){
            q = qmob(t3inv, q);
        }
        else{
            inside_fund_dom = true;
            break;
        }
        //q = vec4(q.x,q.y,q.z,0.0);
    }
    vec3 col;
    if (inside_fund_dom){
        if (q.y > 0.0){
            col = vec3(1.0,q.w,0.0);
        }
        else{
            col = vec3(0.0,q.w,1.0);
        }
    }
    else{
        col = vec3(0.0,q.w,0.0);
    }
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
