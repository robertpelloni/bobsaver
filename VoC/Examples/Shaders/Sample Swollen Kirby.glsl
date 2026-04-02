#version 420

// original https://www.shadertoy.com/view/7dySzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Using code from IQ
//https://iquilezles.org/www/articles/distfunctions/distfunctions.htm

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float PRECISION = 0.001;
const float PI = 3.14159265359;

vec3 white = vec3(1.);
vec3 black = vec3(.0);
vec3 grey = vec3(.6);
vec3 weights_col = vec3(.2, .2, .2);
vec3 pink = vec3(1., .71, .76);
vec3 blush_col = vec3(.99, .5, .65);
vec3 shoes_col = vec3(.87, .02, .35);
vec3 blue = vec3(.0, .0, 1.);

struct Surface {
    float sd;
    vec3 col;
};

mat3 rotateX(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(
        vec3(1., 0., 0.),
        vec3(0., c, -s),
        vec3(0., s, c)
    );
}

mat3 rotateY(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(
        vec3(c, 0., -s),
        vec3(0., 1., 0.),
        vec3(s, 0., c)
    );
}

mat3 rotateZ(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(
        vec3(c, -s, 0.),
        vec3(s, c, 0.),
        vec3(0., 0., 1.)
    );
}

//operator
Surface unionOp(Surface s1, Surface s2) {
    if(s1.sd < s2.sd) {
        return s1;
    } else {
        return s2;
    }
}

Surface intersection(Surface s1, Surface s2) {
    if(s1.sd < s2.sd) {
        return s2;
    } else {
        return s1;
    }
}

Surface smoothUnion(Surface a, Surface b, float k ) {
    float h = clamp( 0.5 + 0.5 * (b.sd - a.sd) / k, 0.0, 1.0 );
    vec3 col = mix( b.col, a.col, h ) - k * h * (1.0 - h);
    return Surface(mix( b.sd, a.sd, h ) - k * h * (1.0 - h), col);
}

Surface ssubstract(Surface a, Surface b, float k ) {
    float h = clamp( 0.5 - 0.5 * (b.sd + a.sd) / k, 0.0, 1.0 );
    vec3 col = mix( b.col, a.col, h ) - k * h * (1.0 - h);
    return Surface(mix( b.sd, -a.sd, h ) + k * h * (1.0 - h), col);
}

//sdf

Surface sdSphere(vec3 p, float r, vec3 col) {
    float d = length(p) - r;
    return Surface(d, col);
}

Surface sdEllipsoid( vec3 p, vec3 r, vec3 col) {
  float k0 = length(p / r);
  float k1 = length(p / (r * r));
  return Surface(k0 * (k0 - 1.0) / k1, col);
}

Surface sdFloor(vec3 p, vec3 col) {
    return Surface(p.y, col);
}

Surface sdVerticalCapsule( vec3 p, float h, float r, vec3 col)
{
  p.y -= clamp( p.y, 0.0, h );
  return Surface(length( p ) - r, col);
}

Surface sdRoundCone( vec3 p, float r1, float r2, float h, vec3 col) {
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 )return Surface(length(q) - r1, col);
  if( k > a*h ) return Surface(length(q-vec2(0.0,h)) - r2, col);
        
  return Surface(dot(q, vec2(a,b) ) - r1, col);
}

Surface sdBox( vec3 p, vec3 b , vec3 col) {
  vec3 q = abs(p) - b;
  return Surface(length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0), col);
}

Surface sdCylinder( vec3 p, float h, float r, vec3 col) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h, r);
  return Surface(min(max(d.x,d.y), 0.0) + length(max(d,0.0)), col);
}

Surface bar(vec3 p, vec3 repulsor, float k) {
    //repulsor to bend the bar
    p = p - normalize(p - repulsor) * k;
    Surface bar = sdCylinder((p - vec3(0., -2.7, .3)) * rotateZ(1.5708), .08, 4., white);
    return bar;
}

Surface arms(vec3 p, Surface modele, bool flex) {
    vec3 pbiceps = p;
    float wave = .5 +.35 * sin(time * 3.);
    pbiceps.y += 1.;
    pbiceps.y *= 1.+.1 * wave;
    pbiceps.y -= 1.;
    pbiceps.xz *= 1.-.1 * wave;

    vec3 pforearm = p;
    pforearm.x += 1.4;
    pforearm.z += 1.1;
    pforearm.y += 1.25;
    pforearm *= 1.+.1 * -wave;
    pforearm -= 1.2;

    //arms
    Surface shoulderL = sdSphere((pbiceps - vec3(.5, .5, -.25)), .6, pink);
    Surface armL = sdVerticalCapsule((pbiceps - vec3(.5, 0.5, -.35)) * rotateZ(90.), 1.5, .45, pink);
    Surface biceps = sdEllipsoid((pbiceps - vec3(1.5, .35, -.25)) * rotateZ(10.), vec3(.6, .45, .45), pink);
    Surface triceps = sdEllipsoid((pbiceps - vec3(1.25, -.35, -.25)) * rotateY(6.) * rotateZ(10.), vec3(.5, .25, .25), pink);
    Surface arm = smoothUnion(shoulderL, armL, .25);
    arm = smoothUnion(biceps, arm, .1);
    arm = smoothUnion(arm, triceps, .5);

    Surface elbow = sdEllipsoid((p - vec3(2.0, -.35, -.25)) * rotateY(6.) * rotateZ(10.), vec3(.65, .5, .5), pink);
    Surface elbow2 = sdEllipsoid((pforearm - vec3(2.35, -.65, -.25)) * rotateY(6.) * rotateZ(10.), vec3(.45, .3, .3), pink);
    arm = smoothUnion(arm, elbow, .2);
    arm = smoothUnion(arm, elbow2, .2);

    Surface forearmL = sdEllipsoid((pforearm - vec3(2.5, 0.2, -.05)) * rotateX(-60.) /* rotateZ(-wave)*/, vec3(.5, 1.2, .45), pink);
    Surface hand;
    if(flex)
        hand = sdRoundCone((pforearm - vec3(2.5, 1., .25)) * rotateX(50.) * rotateZ(87.), .25, .5, .5, pink);
    else {
         hand = sdRoundCone((pforearm - vec3(2.5, 1., .25)) * rotateX(50.) * rotateZ(0./*87.*/), .25, .5, .5, pink);
         Surface thumb = sdEllipsoid((pforearm  - vec3(2.1, 1.4, .8)) * rotateY(-1.3), vec3(.3, .15, .15), pink);
         hand = smoothUnion(hand, thumb, .2);
    }
    forearmL = smoothUnion(hand, forearmL, .1);
    arm = smoothUnion(arm, forearmL, .1);
    modele = smoothUnion(arm, modele, .1);

    return modele;
}

Surface weights(vec3 p, Surface modele) {
    float wave = .5 +.35 * sin(time * 3.);
    p.x += 1.4;
    p.z += 1.1;
    p.y += 1.25;
    p.xzy *= 1.+.1 * -wave;
    p.xzy -= 1.2;

    Surface bar = bar(p, vec3(0., -5.5, .0), 4.5);

    vec3 op = p;
    op.x = abs(op.x);
    Surface weight1 = sdCylinder((op - vec3(5.45, .6, .65)) * rotateZ(1.8), 1.9, .4, weights_col);
    Surface weight_sub = sdCylinder((op - vec3(5., .7, .65)) * rotateZ(1.8), 1., .2, grey);
    Surface security1 = sdCylinder((op - vec3(5., .8, .65)) * rotateZ(1.8), .3, .2, grey);
    weight1 = ssubstract(weight_sub, weight1, .1);
    weight1 = unionOp(weight1, security1);
    Surface weight2 = sdCylinder((op - vec3(6., .4, .65)) * rotateZ(1.8), 1.7, .2, weights_col);
    Surface weight3 = sdCylinder((op - vec3(6.35, .3, .65)) * rotateZ(1.8), 1.3, .15, weights_col);
    Surface weight_sub2 = sdCylinder((op - vec3(6.5, .25, .65)) * rotateZ(1.8), .5, .15, grey);
    Surface security = sdCylinder((op - vec3(6.5, .25, .65)) * rotateZ(1.8), .25, .15, grey);
    weight3 = ssubstract(weight_sub2, weight3, .1);
    Surface weights = unionOp(weight1, weight2);
    weights = unionOp(weights, weight3);
    weights = unionOp(weights, security);
    bar = unionOp(bar, weights);

    modele = ssubstract(bar, modele, .2);
    modele = unionOp(bar, modele);
    return modele;
}

Surface legs(vec3 p, Surface modele) {
    //thigh
    Surface thigh = sdRoundCone((p - vec3(0.5, -2.1, .0)) * rotateZ(6.2), .5, .7, .9, pink);
    Surface leg = smoothUnion(thigh, modele, .4);
    modele = unionOp(leg, modele);
    Surface quadri = sdEllipsoid((p - vec3(.75, -1.5, .2)) * rotateZ(50.3) * rotateX(50.05), vec3(.5, .9, .6), pink);
    Surface isq = sdEllipsoid((p - vec3(.35, -1.5, .35)) * rotateZ(50.2) * rotateX(50.05), vec3(.45, .9, .4), pink);
    Surface m = unionOp(quadri, isq);
    modele = smoothUnion(m, modele, .1);
    //Knee
    Surface knee = sdRoundCone((p - vec3(0.65, -2.6, .05)) * rotateZ(6.2), .4, .4, .2, pink);
    modele = smoothUnion(knee, modele, .1);
    Surface knee_cap = sdRoundCone((p - vec3(0.7, -2.7, .35)) * rotateZ(6.2) * rotateX(50.5), .15, .3, .3, pink);
    modele = smoothUnion(knee_cap, modele, .05);
    //calf
    Surface calf = sdRoundCone((p - vec3(0.65, -3.9, .0)) * rotateZ(6.2), .3, .5, .8, pink);
    modele = smoothUnion(calf, modele, .2);

    return modele;
}

Surface eyes(vec3 p, Surface modele) {
    p.y *= 1./ smoothstep(.0,.15,abs(sin(time)));
    Surface eyeL = sdEllipsoid((p - vec3(-.3, 0.5, 1.3)) * rotateX(6.6), vec3(.13, .43, .1), black);
    Surface pupL = sdEllipsoid((p - vec3(-.3, 0.7, 1.3)) * rotateX(6.7), vec3(.08, .14, .05), white);
    eyeL = ssubstract(pupL, eyeL, .1);
    eyeL = unionOp(eyeL, pupL);
    Surface blueL = sdEllipsoid((p - vec3(-.3, 0.3, 1.42)) * rotateX(6.5), vec3(.08, .17, .05), blue);
    Surface subblue = sdEllipsoid((p - vec3(-.3, 0.4, 1.4)) * rotateX(6.5), vec3(.08, .17, .1), blue);
    blueL = unionOp(blueL, subblue);
    blueL = ssubstract(subblue, blueL, .01);
    eyeL = unionOp(eyeL, blueL);
    modele = ssubstract(eyeL, modele, .1);
    modele = unionOp(eyeL, modele);
    return modele;
}

Surface kirby(vec3 p, bool flex) {
    vec3 op = p;
    vec3 pbody = p;
    float wave = .5 + .35 * sin(time * 3.);
    pbody.y += 1.;
    pbody.y *= 1. + .1 * wave;
    pbody.y -= 1.;
    pbody *= 1.-.1 * wave;

    //body
    Surface body = sdSphere(pbody, 1.5, pink);

    //butt
    op = pbody;
    op.x = abs(p.x) -.9;
    Surface butt = sdSphere(op - vec3(-.45, -1.35, -.45), .6, pink);
    Surface modele = smoothUnion(body, butt, .3);

    //eyes
    op = pbody;
    op.x = abs(op.x) -.6;
    modele = eyes(op, modele);

    //blush
    op = pbody;
    op.x = abs(op.x) - 1.5;
    Surface blush = sdEllipsoid((op - vec3(-.75, -.0, 1.25)) * rotateY(.55), vec3(.15, .05, .05), blush_col);
    modele = ssubstract(blush, modele, .1);
    modele = smoothUnion(modele, blush, .1);
    //mouth
    Surface mouth = sdEllipsoid((pbody - vec3(.0, .75, 1.3)), vec3(.6, 1.2, .5), pink);
    Surface box_mouth= sdBox((pbody - vec3(.0, 0.95, 1.3)), vec3(.8, 1., .65), shoes_col);
    mouth = ssubstract(box_mouth, mouth, .5);
    modele = ssubstract(mouth, modele, .1);
    Surface mouthes = sdRoundCone((pbody - vec3(0.0, -.5, 1.5)) * rotateX(50.5), .15, .3, .3, black);
    mouth = unionOp(box_mouth, mouth);    
    //arms
    op = p;
    op.x = abs(op.x) - .8;
    modele = arms(op - vec3(0., -.1, 0.2), modele, flex);
    //legs
    op = p;
    op.x = abs(op.x) - .2;
    modele = legs(op - vec3(0., -.2, 0.), modele);
    //shoes
    op = p;
    op.x = abs(op.x) - 2.15;
    Surface shoeL = sdEllipsoid((op - vec3(-1.1, -5.1, .3)) * rotateY(10.), vec3(.6, 1., 1.), shoes_col);
    Surface box= sdBox((op - vec3(-1.1, -5.5, .3)) * rotateY(10.), vec3(.5, .6, 1.), shoes_col);
    shoeL = ssubstract(box, shoeL, .3);
    modele = smoothUnion(shoeL, modele, .1);
    //weights
    if(!flex)
        modele = weights(p - vec3(.0, .0, .1), modele);

    return modele;
}

Surface sdScene(vec3 p) {
    //change false by true if you want to see kirby flex without the weights
    Surface kirby = kirby(p, false);
    Surface floor = sdFloor(p - vec3(.0, -5., .0), grey * 1.3);
    return unionOp(kirby, floor);
}

vec3 computeNormal(vec3 p) {
    float e = 0.0005;
    return normalize(vec3(
        sdScene(vec3(p.x + e, p.y, p.z)).sd - sdScene(vec3(p.x - e, p.y, p.z)).sd,
        sdScene(vec3(p.x, p.y + e, p.z)).sd - sdScene(vec3(p.x, p.y - e, p.z)).sd,
        sdScene(vec3(p.x, p.y, p.z + e)).sd - sdScene(vec3(p.x, p.y, p.z - e)).sd
    ));
}

Surface rayMarching(vec3 ro, vec3 rd, float start, float end) {
    float depth = start;
    Surface co;
    const int step = 255;
    for(int i = 0; i < MAX_MARCHING_STEPS; ++i) {
        vec3 p = ro + depth * rd;
        co = sdScene(p);
        depth += co.sd;
        if(co.sd < PRECISION || depth > end)
            break;
    }
    co.sd = depth;
    return co;
}

vec3 blinn_phong(vec3 lightDirection, vec3 normal, vec3 rd) {
    vec3 lightColor = vec3 (1.,1.,1.);
    //ambient
    float ka = .4;
    vec3 ia = lightColor;
    vec3 ambient = ia * ka;

    //diffuse
    float kd = .5;
    vec3 id = lightColor;
    float diff = clamp(dot(lightDirection, normal), 0., 1.);
    vec3 diffuse = kd * diff * id;

    //specular
    float ks = .5;
    vec3 is = lightColor;
    float alpha = 10.;
    float dotRV = clamp(dot(reflect(-lightDirection, normal), -rd), 0., 1.);
    vec3 specular = ks * pow(dotRV, alpha) * is;

    return ambient + diffuse + specular;
}

mat2 rotate2d(float theta) {
  float s = sin(theta), c = cos(theta);
  return mat2(c, -s, s, c);
}

mat3 camera(vec3 cameraPos, vec3 lookAtPoint) {
    vec3 cd = normalize(lookAtPoint - cameraPos);
    vec3 cr = normalize(cross(vec3(0, 1, 0), cd));
    vec3 cu = normalize(cross(cd, cr));
    
    return mat3(-cr, cu, -cd);
}

void main(void) {
    vec2 uv =  (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    vec3 backgroundColor = vec3(0.6);
    vec2 mouseUV = mouse*resolution.xy.xy / resolution.xy;
  
    if (mouseUV == vec2(0.0)) 
        mouseUV = vec2(0.5);

    vec3 col = vec3(0.);
    vec3 ro = vec3(0., -1., 6.5);
    vec3 lp = vec3(0);

    //camera
    float cameraRadius = 2.;
    ro.yz = ro.yz * cameraRadius * rotate2d(mix(-PI/2., PI/20., mouseUV.y));
    ro.xz = ro.xz * rotate2d(mix(-PI, PI, mouseUV.x)) + vec2(lp.x, lp.z);
    vec3 rd = camera(ro, lp) * normalize(vec3(uv, -1));

    Surface co = rayMarching(ro, rd, MIN_DIST, MAX_DIST);
    if(co.sd > MAX_DIST) {
        col = backgroundColor;
    } else {
        vec3 p = ro + co.sd * rd;
        vec3 normal = computeNormal(p);

        //light
        vec3 lightPosition = vec3(0., 2., 3.);
        vec3 lightDirection = normalize(lightPosition - p);
        col = co.col * blinn_phong(lightDirection, normal, rd) + backgroundColor * .2;
    }
    glFragColor = vec4(col, 1.);
}
