#version 420

// original https://www.shadertoy.com/view/MddfD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Joint work with Dave Bachman. 
// An approximation to the Cannon-Thurston map from the boundary circle of the 
// universal cover of the fiber of the figure eight knot complement to the 
// boundary of 3D hyperbolic space.

// This is a view of a horizontal slice through the upper half space model 
// of three-dimensional hyperbolic space. The height varies with time from 
// 0.001 to 0.201. The pattern is made as follows: Each pixel is inside of 
// a tetrahedron of the lift of the triangulation of the figure eight knot
// complement to H^3. We move it by elements of the fundamental group until
// it is inside of the fundamental domain, which consists of two tetrahedra
// with vertices (infinity, 0, 1, e^(i pi/6)), and (infinity, 0, 1, e^(-i pi/6)).
// As we go, we track how many times we cross through the fiber. If the answer is
// zero we colour the pixel grey (0.5,0.5,0.5). If the number of times we
// cross through is positive then the pixel gets more white, and if it
// is negative then the pixel gets more black. 

// The result is that as we decrease the height of the horizontal slice down
// towards zero, the points coloured (0.5,0.5,0.5) form a better and better
// approximation to the image of the Cannon-Thurston map, a sphere-filling curve.

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
const vec2 c0 = vec2(0.0,0.0);
const vec2 c1 = vec2(1.0,0.0);
const vec2 ci = vec2(0.0,1.0);

bool needt1(in vec4 q){  // q is wrong side of face of fund domain corresponding to transformation 1
    return q.x*(-0.5*sqrt3) + q.y*0.5 > 0.0;
}
bool needt1inv(in vec4 q){  // q is wrong side of face of fund domain corresponding to inv transformation 1
    vec4 center = c2q((c1 + winv)/3.0);
    vec4 qmc = q - center;
    return qmc.x*qmc.x + qmc.y*qmc.y + qmc.z*qmc.z < 1.0/3.0;
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
}

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
    
    vec2 p = vec2(0.1,0.001) + 1.5*(-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;
    vec4 q = vec4(p, 0.001+0.1*(0.75 + cos(time) + 0.25*cos(2.0*time)), 0.0);
    //vec4 q = vec4(p, 0.0001, 0.0);
    
    int crossing_count = 0;
    bool inside_fund_dom = false;
    for(int i=0;i<512;i++){
        if (needt1(q)){
            q = qmob(t1, q);
        }
        else if (needt1inv(q)){
            q = qmob(t1inv, q);
        }
        else if (needt2(q)){
            q = qmob(t2, q);
            crossing_count -= 1;
        }
        else if (needt2inv(q)){
            q = qmob(t2inv, q);
            crossing_count += 1;
        }
        else if (needt3(q)){
            q = qmob(t3, q);
            crossing_count -= 1;
        }
        else if (needt3inv(q)){
            q = qmob(t3inv, q);
            crossing_count += 1;
        }
        else{
            inside_fund_dom = true;
            break;
        }
    }
    vec3 col;
    if (inside_fund_dom){
        float c = 0.5 + float(crossing_count)/10.0;
        col = vec3(c,c,c);
    }
    else{
        col = vec3(0.0,1.0,0.0);
    }
    
    glFragColor = vec4(col,1.0);
}
