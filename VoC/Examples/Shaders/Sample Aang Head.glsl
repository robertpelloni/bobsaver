#version 420

// original https://www.shadertoy.com/view/wtcXRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Felt like doing some character that I know. Thought Aang would be a
good fit. No hair... And the arrow would be fun to figure out.
*/
float PI = 3.14159;
vec3 rotate3D(vec3 point, vec3 rotation) {
    vec3 r = rotation;
    mat3 rz = mat3(cos(r.z), -sin(r.z), 0,
                   sin(r.z),  cos(r.z), 0,
                   0,         0,        1);
    mat3 ry = mat3( cos(r.y), 0, sin(r.y),
                    0       , 1, 0       ,
                   -sin(r.y), 0, cos(r.y));
    mat3 rx = mat3(1, 0       , 0        ,
                   0, cos(r.x), -sin(r.x),
                   0, sin(r.x),  cos(r.x));
    return rx * ry * rz * point;
}
float sdfSphere(vec3 position, vec3 center, float radius) {
    return distance(position, center) - radius;
}
float sdfEllipsoid(vec3 position, vec3 center, vec3 radii) {
    position -= center;
    float k0 = length(position/radii);
    float k1 = length(position/(radii*radii));
    return k0*(k0-1.0)/k1;
}
float sdfEllipsoidRotated(vec3 position, vec3 center, vec3 radii, vec3 rotation) {
    position -= center;
    position = rotate3D(position, rotation);
    float k0 = length(position/radii);
    float k1 = length(position/(radii*radii));
    return k0*(k0-1.0)/k1;
}
float sdfPlane( vec3 position, vec4 n ) {
    return dot(position, normalize(n.xyz)) + n.w;
}
float sdfRoundBoxRotated(vec3 position, vec3 center, vec3 box, vec3 rotation, float radius) {
    position -= center;
    position = rotate3D(position, rotation);
    vec3 q = abs(position) - box;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - radius;
}
float dot2(vec2 v) {
    return dot(v, v);
}
vec3 bendSpaceZ (vec3 position, float degree) {
    //position = rotate3D(position, vec3(0.0, PI/2.0, 0.0));
    float k = degree;
    float c = cos(k*position.y);
    float s = sin(k*position.y);
    mat2  m = mat2(c,-s,s,c);
    vec2  q = m*position.xy;
    return vec3(q, position.z);
}
vec4 sdfJoint3DSphere(vec3 position, vec3 start, vec3 rotation, float len, float angle, float thickness) {
    vec3 p = position;
    float l = len;
    float a = angle;
    float w = thickness;
    p -= start;
    p = rotate3D(p, rotation);

    if( abs(a)<0.001 ) {
        return vec4( length(p-vec3(0,clamp(p.y,0.0,l),0))-w, p );
    }

    vec2  sc = vec2(sin(a),cos(a));
    float ra = 0.5*l/a;
    p.x -= ra;
    vec2 q = p.xy - 2.0*sc*max(0.0,dot(sc,p.xy));
    float u = abs(ra)-length(q);
    float d2 = (q.y<0.0) ? dot2( q+vec2(ra,0.0) ) : u*u;
    float s = sign(a);
    return vec4( sqrt(d2+p.z*p.z)-w,
               (p.y>0.0) ? s*u : s*sign(-p.x)*(q.x+ra),
               (p.y>0.0) ? atan(s*p.y,-s*p.x)*ra : (s*p.x<0.0)?p.y:l-p.y,
               p.z );
}
float smin(float d1, float d2, float k) {
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}
float smax(float d1, float d2, float k) {
    float h = max(k-abs(d1-d2),0.0);
    return max(d1, d2) + h*h*0.25/k;
}

vec2 aangHead(vec3 position) {
    vec3 symPosX = vec3(abs(position.x), position.yz);
    float material = 1.0;
    float d, d1, d2;

    // Basic head sphere
    d = sdfEllipsoid(position, vec3(0.0), vec3(0.4, 0.5, 0.5));
    // basic jaw
    d1 = sdfRoundBoxRotated(position, vec3(0.0, -0.3, -0.1), vec3(0.08, 0.2, 0.20),
                            vec3(0.0), 0.2);
    d2 = sdfRoundBoxRotated(position, vec3(0.0, -0.90, 0.1), vec3(0.5, 0.8, 0.3),
                            vec3(PI/2.5, 0.0, 0.0), 0.0);
    d1 = smax(d1, -d2, 0.3);
    d2 = sdfRoundBoxRotated(symPosX, vec3(0.30, -0.56, -0.40), vec3(0.38, 0.45, 0.08),
                            vec3(-0.6, -1.3, -0.2), 0.0);
    //d1 = smin(d1, d2, 0.1);
    d1 = smax(d1, -d2, 0.15);
    d2 = sdfRoundBoxRotated(symPosX, vec3(0.35, -0.56, -0.50), vec3(0.58, 0.53, 0.18),
                            vec3(-0.0, -1.1, -0.0), 0.0);
    //d1 = smin(d1, d2, 0.1);
    d1 = smax(d1, -d2, 0.1);
    d = smin(d, d1, 0.1);
    // sculpt head
    d1 = sdfRoundBoxRotated(symPosX, vec3(0.51, 0.0, 0.0), vec3(0.07, 1.0, 1.0),
                            vec3(0.0, 0.0, -0.1), 0.01);
    d = smax(d, -d1, 0.1);
    // ears
    d1 = sdfEllipsoidRotated(symPosX, vec3(0.38, -0.15, 0.1), vec3(0.12, 0.15, 0.03),
                             vec3(-0.3, -PI/2.9, 0.0));
    d2 = sdfSphere(symPosX, vec3(0.43, -0.15, 0.1), 0.001);
    d1 = smax(d1, -d2, 0.1);
    d = smin(d, d1, 0.01);

    // eye sockets
    d1 = sdfRoundBoxRotated(position, vec3(0.0, -0.04, -0.57), vec3(0.2, 0.1, 0.1),
                            vec3(PI/4.0, 0.0, -0.0), 0.01);
    d = smax(d, -d1, 0.2);
    // nose
    d1 = sdfRoundBoxRotated(position, vec3(0.0, -0.12, -0.45), vec3(0.005, 0.12, 0.05),
                            vec3(0.7, 0.0, 0.0), 0.02);
    d = smin(d, d1, 0.1);
    d1 = sdfRoundBoxRotated(position, vec3(0.0, -0.22, -0.53), vec3(0.05, 0.005, 0.05),
                            vec3(0.0, PI/4.0, 0.0), 0.0);
    d = smin(d, d1, 0.1);
    // mouth
    d1 = sdfEllipsoid(vec3(symPosX.x, symPosX.y-0.5*pow(symPosX.x, 1.2), symPosX.z),
                      vec3(0.0, -0.42, -0.5), vec3(0.15, 0.07, 0.6));
    d = smax(d, -d1, 0.01);
    d1 = sdfSphere(position, vec3(0.0, -0.42, -0.35), 0.13);
    if (d1 < d) {
        material = 6.0;
    }
    d = smin(d, d1, 0.01);
    d1 = sdfJoint3DSphere(position, vec3(0.08, -0.36, -0.45),
                          vec3(PI/2.0, -PI/1.4, 0.0),
                          0.2, PI/4.0, 0.01).x;
    if (d1 < d) {
        material = 2.0;
    }
    d = smin(d, d1, 0.01);
    d1 = sdfJoint3DSphere(position, vec3(0.08, -0.47, -0.45),
                          vec3(PI/2.0, -PI/1.4, 0.0),
                          0.2, PI/4.0, 0.01).x;
    if (d1 < d) {
        material = 2.0;
    }
    d = smin(d, d1, 0.01);
    // cheeks
    d1 = sdfSphere(symPosX, vec3(0.2, -0.22, -0.35), 0.05);
    d = smin(d, d1, 0.2);
    // eyes
    d1 = sdfSphere(symPosX, vec3(0.15, -0.07, -0.35), 0.11);
    if (d1 < d) {
        material = 2.0;
    }
    d = smin(d, d1, 0.01);
    d1 = sdfSphere(symPosX, vec3(0.15, -0.07, -0.41), 0.06);
    if (d1 < d) {
        material = 3.0;
    }
    d = smin(d, d1, 0.01);
    d1 = sdfSphere(symPosX, vec3(0.15, -0.07, -0.445), 0.03);
    if (d1 < d) {
        material = 4.0;
    }
    d = smin(d, d1, 0.01);
    // eye brows
    d1 = sdfJoint3DSphere(symPosX, vec3(0.1, 0.13+0.01*sign(position.x), -0.455),
                          vec3(0.0, -0.9, -PI/3.2),
                          0.2, 0.9, 0.01).x;
    if (d1 < d) {
        material = 5.0;
    }
    d = smin(d, d1, 0.01);

    return vec2(d, material);
}

int calculateArrow(vec3 position) {
    // To calculate the arrow, we take the origin as 0. If facing back (z=1)
    // is 0, we trace a circle on the yz plane, and calculate the angle made
    // we use that to calculate the stem of the arrow, and the position of the
    // pointyhead.
    if (abs(position.x) > 0.20) {
        return 0;
    }
    float angle = atan(position.y, position.z);
    float maxAngle = PI-0.2;
    float arrowAngle = PI/6.0;
    if (-PI/2.0 < angle && angle < maxAngle) {
        // pointy head
        if (angle > maxAngle-arrowAngle) {
            float rem = (angle-(maxAngle-arrowAngle)) / arrowAngle;
            rem = -1.0 * (rem-1.0);
            if (abs(position.x) < 0.20*rem) {
                return 1;
            }
        } else if (abs(position.x) < 0.11) {
            return 1;
        }
    }
    return 0;
}

vec4 distanceField(vec3 position) {
    vec2 d = aangHead(position);
    return vec4(d, 0.0, 0.0);
}

vec3 calcNormal(vec3 p) {
    // We calculate the normal by finding the gradient of the field at the
    // point that we are interested in. We can find the gradient by getting
    // the difference in field at that point and a point slighttly away from it.
    const float h = 0.0001;
    return normalize( vec3(
                           -distanceField(p).x+ distanceField(p+vec3(h,0.0,0.0)).x,
                           -distanceField(p).x+ distanceField(p+vec3(0.0,h,0.0)).x,
                           -distanceField(p).x+ distanceField(p+vec3(0.0,0.0,h)).x
                     ));
}

vec4 raymarch(vec3 direction, vec3 start) {
    // We need to cast out a ray in the given direction, and see which is
    // the closest object that we hit. We then move forward by that distance,
    // and continue the same process. We terminate when we hit an object
    // (distance is very small) or at some predefined distance.
    float far = 15.0;
    vec3 pos = start;
    float d = 0.0;
    vec4 obj = vec4(0.0, 0.0, 0.0, 0.0);
    for (int i=0; i<100; i++) {
        obj = distanceField(pos);
        float dist = obj.x;
        pos += dist*direction;
        d += dist;
        if (dist < 0.01) {
            break;
        }
        if (d > far) {
            break;
        }
    }
    return vec4(d, obj.yzw);
}

void main(void)
{
    // Normalise and set center to origin.
    vec2 p = gl_FragCoord.xy/resolution.xy;
    p -= 0.5;
    p.y *= resolution.y/resolution.x;

    float mouseX = ((mouse.x*resolution.xy.x/resolution.x)-0.5) * 2.0 * 3.14159/2.0;
    mouseX = -0.3;
    mouseX = 0.4*sin(time/3.6);
    vec3 cameraPosition = vec3(0.0, 0.0, -3.0);
    vec3 planePosition = vec3(p, 1.0) + cameraPosition;

    mat2 camRotate = mat2(cos(mouseX), -sin(mouseX), sin(mouseX), cos(mouseX));
    cameraPosition.xz = camRotate * cameraPosition.xz;
    planePosition.xz = camRotate * planePosition.xz;

    float yRotate = 0.1;
    yRotate = 0.2*sin(time/4.2);
    camRotate = mat2(cos(yRotate), -sin(yRotate), sin(yRotate), cos(yRotate));
    cameraPosition.yz = camRotate * cameraPosition.yz;
    planePosition.yz = camRotate * planePosition.yz;

    vec3 lookingDirection = (planePosition - cameraPosition);

    // This was fun to sort out, but is it the best way?
    float lightTime = time/3.0;
    float multiplier = -1.0 + (step(-0.0, sin(lightTime*3.14159)) *2.0);
    float parabola = (4.0 * fract(lightTime) * (1.0-fract(lightTime)));
    float lightX = multiplier*parabola *-1.2;
    vec3 lightPoint = normalize(vec3(lightX, 1.0, -1.0));
    vec3 lightFacing = lightPoint - vec3(0.0);
    // lightFacing = vec3(1.0, 1.0, -0.3) - vec3(0.0);

    // raymarch to check for colissions.
    vec4 obj = raymarch(lookingDirection, planePosition);
    float dist = obj.x;
    vec3 color = vec3(0.01);
    if (dist < 15.0) {
        vec3 normal = calcNormal(planePosition+ dist*lookingDirection);
        int arrow = calculateArrow(planePosition+ dist*lookingDirection);
        float light = dot(lightFacing, normal);
        light = max(light, 0.0);
        if (obj.y < 1.5) {
            // skin
            color = vec3(0.505, 0.205, 0.105);
            color += 0.3* smoothstep(0.1, 1.0, light);
            if (arrow==1) {
                color = vec3(0.21, 0.21, 0.31);
                color += 0.1* smoothstep(0.1, 1.0, light);
            }
        } else if (obj.y < 2.5) {
            //eyes
            color = vec3(0.75, 0.75, 0.85);
            color += 0.1 * smoothstep(0.5, 1.0, light);
        } else if (obj.y < 3.5) {
            color = vec3(0.21, 0.21, 0.31);
            color += 0.7 * smoothstep(0.4, 1.0, pow(light, 5.0));
        } else if (obj.y < 4.5) {
            color = vec3(0.01);
            color += 0.5 * smoothstep(0.4, 1.0, pow(light, 5.0));
        } else if (obj.y < 5.5) {
            // eyebrows
            color = vec3(0.05, 0.02, 0.01);
            color += 0.05 * smoothstep(0.4, 1.0, pow(light, 5.0));
        } else if (obj.y < 6.5) {
            // mouth
            color = vec3(0.15, 0.02, 0.01);
            color += 0.1 * smoothstep(0.4, 1.0, pow(light, 5.0));
        }
    }
    // gamma correction
    color = pow( color, vec3(1.0/2.2) );
    glFragColor = vec4(color,1.0);
}
