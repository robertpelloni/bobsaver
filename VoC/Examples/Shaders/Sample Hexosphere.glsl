#version 420

// original https://www.shadertoy.com/view/wsXyW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 128
#define MAX_DISTANCE 3.
#define MIN_DISTANCE 0.001
#define SPEED 3.
#define SIZE 3.
#define SPHERE_SIZE .8

float n21(vec2 p) {
    return fract(sin(p.x*123.453 + p.y*4567.543) * 67894.432 );
}

float hexDist(vec2 uv) {
    uv = abs(uv);
    return max(uv.x, dot(uv, normalize(vec2(1., 1.73))));
}

vec4 hexCoords(vec2 uv) {
    vec2 r = vec2(1., 1.73);
    vec2 h = r * .5;

    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;

    vec2 gv;

    if (length(a) < length(b)) {
        gv = a;
    } else {
        gv = b;
    }

    float x = atan(gv.x, gv.y);
    float y = .5 - hexDist(gv);

    vec2 id = uv - gv;

    return vec4(x, y, id.xy);
}

vec3 getTexture(vec2 uv) {
    vec3 col = vec3(0.);

    float size = 3.;

    vec2 ouv = uv;

    vec2 id = floor(uv*size);
    uv = fract(uv*size) - .5;

    vec3 c = vec3(0.);

    for(int x = -1 ; x <= 1 ; x++) {
        for(int y = -1 ; y <= 1 ; y++) {
            vec2 offset = vec2(x, y);
            vec2 nid = id + offset;
            float n = n21(nid);
            if (n > .2) {
                float n1 = fract(n*123.456);
                float n2 = fract(n*5678.543);
                vec3 color = vec3(n, n1, n2);
                vec2 shift = vec2(n1 - .5, n2 - .5)*sin(time + n*n1 + n2);
                c = max(c, ((0.01 + 0.02*n2)/length(uv - offset - shift)) * color);
            }
        }
    }

    col += c;

    return col;
}

float getHeight(vec3 p, vec4 hex) {
    float base = 0. + sin(hex.a/hex.b + time*2.)*.02;
    base = clamp(hex.y/2., 0., base + SPHERE_SIZE/30.);
    return base;
}

void main(void) {

    vec2 uv = gl_FragCoord.xys.xy / resolution.xy;
    uv -= .5;
    uv.x *= resolution.x / resolution.y;

    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;

    vec3 col = vec3(0.);

    float a = time;

    vec3 ro = vec3(0., 0., -2.);
    vec3 lookat = vec3(0., 0., 3.);
    float zoom = 1.;

    vec3 f = normalize(lookat - ro);
    vec3 r = normalize(cross(vec3(0., 1., 0.), f));
    vec3 u = cross(f, r);
    vec3 c = ro + f * zoom;
    vec3 i = c + uv.x * r + uv.y * u;

    vec3 rd = normalize(i - ro);

    float ds, dt = 0.;
    vec3 p;
    float x,y = 0.;
    vec2 suv;
    vec4 hex;

    for(int i = 0 ; i < MAX_STEPS ; i++) {
        p = ro + rd * ds;

        x = acos(p.y/length(p));
        y = atan(p.z, p.x) + time/SPEED;

        suv = vec2(x, y);

        hex = hexCoords(suv*SIZE);
        float base = SPHERE_SIZE + sin(hex.a*hex.b + time*10.)*.0;

        dt = length(p) - (base + getHeight(p, hex));
        ds += dt * .6;

        if (abs(dt) < MIN_DISTANCE || ds > MAX_DISTANCE) {
            break;
        }
    }

    float t = time*3.;

    if (dt < MIN_DISTANCE) {
        col += getTexture(suv);
        //vec4 hex = hexCoords(suv*SIZE);

        float b = smoothstep(.9, 1., sin(t + sin(t)/cos(t + sin(t*3.+t))) * .5 + .5);

        vec3 gridColor = mix(vec3(0., 1., 1.), mix(vec3(1.,0.,0.), vec3(0.,1.,0.), sin(time)), cos(time/2.));

        col += pow(.005/hex.y, .6) * gridColor * b;

        col += vec3(n21(hex.ba + 100.))*.6;
    } else {
        col = getTexture(uv + vec2(time/(SPEED*2.), 0.));
    }

    glFragColor = vec4(clamp(col, 0., 1.), 1.);

}
