#version 420

// original https://neort.io/art/bmvd6pk3p9f7m1g03a50

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 回転行列
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float clock(vec3 pos) {
    pos.x = pos.x + sin(pos.y * 5.  + time  *2. ) * .2;
    vec3 pos_origin  = pos;
    pos.xy = pos.xy * rot(sin(time * 0.5) * 8. ) ;
    float side1 = sdVerticalCapsule(pos,.75,.1 );
    pos = pos_origin;
    pos.xy = pos.xy * rot(- sin(time) * 10.) ;
    float side2 = sdVerticalCapsule(pos,.45,.1 );
    pos = pos_origin;
    pos.yz =  pos.yz *rot(1.5) ;
    float side3 = sdCappedCylinder(pos, 1.1,.2);

    return max(side3, -min(side1,side2))/ .3;
}

void main( void ) {
    vec2 p = (gl_FragCoord.xy * 2. - resolution.xy) / min(resolution.x, resolution.y);
    vec3 ro = vec3(0., 0. , 0. + time * 4.);
    vec3 ray = normalize(vec3(p, 2.5));
        ray.xy = ray.xy * rot(sin(time * .1) * .20);
        ray.yz = ray.yz * rot(sin(time * .1) * .30);
        ray.xz = ray.xz * rot(sin(time * .05) * .20);
    float t = 5.;
    vec3 col = vec3(0.);
    float ac = 0.0;

    for (int i = 0; i < 180; i++){
        vec3 pos = ro + ray * t;
        pos = mod(pos-2., 4.) -2.;
        float d = clock(pos);

        d = max(abs(d), 0.2);
        ac += exp(-d*3.);

        t += d* 0.08;
    }
    col = vec3(ac * 0.01);
        col.x += col.x * abs(sin(time * 0.1)) * .7 + 0.2;
        col.y +=  0.2;
        col.z += col.z * sin(time * 0.1) * 0.7 + 0.4;
    glFragColor = vec4(col ,1.0);
}
