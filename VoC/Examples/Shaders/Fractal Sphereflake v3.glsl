#version 420

// original https://www.shadertoy.com/view/NlSBRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
SDF Ray marcher is adapted from me following an Inigo Quilez tutorial.
Thank you Inigo for inspiring me!

sdfSphereFlake formulas are from me.

code/perf are far from optimized! Feel free to suggest rewrites!

Feel free to play around with the rotators at lines 267, 268
*/
float PI = 3.141592653;
float MAX_CARE_DISTANCE = 20.0;
int FRACTAL_ITERATIONS = 5;

vec4 sdfSphereFlake(in vec3 pt, in float radius) {
    // centre of starting sphere
    vec3 ptO, ptO_next, ptO_saved;
    // normalized vector for UP direction
    vec3 dirUp, dirUp_next, dirUp_saved;
    // normalized vector for equator phase
    vec3 dirEqPhase, dirEqPhase_next, dirEqPhase_saved;
    // scale factor determining sphere size
    float scale, scale_next;
    // temp var named after the famous right hand rule
    vec3 middleFinger;

    // set initial values
    ptO = vec3(0.,0.,0.);
    dirUp = vec3(0.,1.,0.);
    dirEqPhase = vec3(1.,0.,0.);
    scale = radius;
    middleFinger = normalize(cross(dirUp, dirEqPhase));

    // set values that need to be calculated as we "recurse" down the sphere flake fractal
    int iterations = 0;
    float lowestDistance = length(pt) - radius;
    int chosenIteration = 0;
    float distanceChild;
    float lowestDistanceChild;

    while(iterations < FRACTAL_ITERATIONS && lowestDistance > 0.) {
        scale_next = scale / 3.;
        lowestDistanceChild = MAX_CARE_DISTANCE;
        // child 1:
        dirUp_next = dirEqPhase;
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = -dirUp;

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }

        // child 2:
        dirUp_next = -dirEqPhase;
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = -dirUp;

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }

        // child 3:
        dirUp_next = normalize(0.5 * dirEqPhase + 0.5 * sqrt(3.) * middleFinger);
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = -dirUp;

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }

        // child 4:
        dirUp_next = normalize(0.5 * dirEqPhase - 0.5 * sqrt(3.) * middleFinger);
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = -dirUp;

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }

        // child 5:
        dirUp_next = normalize( - 0.5 * dirEqPhase + 0.5 * sqrt(3.) * middleFinger);
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = -dirUp;

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }

        // child 6:
        dirUp_next = normalize(- 0.5 * dirEqPhase - 0.5 * sqrt(3.) * middleFinger);
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = -dirUp;

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }

        // child 7:
        dirUp_next = normalize(-middleFinger + sqrt(3.) * dirUp);
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = normalize(dirUp - 0.5 * sqrt(3.) * dirUp_next);

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }
        // child 8:
        dirUp_next = normalize(0.5 * sqrt(3.) * dirEqPhase + 0.5 * middleFinger + sqrt(3.) * dirUp);
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = normalize(dirUp - 0.5 * sqrt(3.) * dirUp_next);

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }
        // child 9:
        dirUp_next = normalize(- 0.5 * sqrt(3.) * dirEqPhase + 0.5 * middleFinger + sqrt(3.) * dirUp);
        ptO_next = ptO + dirUp_next * scale * (4./3.);
        dirEqPhase_next = normalize (dirUp - 0.5 * sqrt(3.) * dirUp_next);

        distanceChild = length(ptO_next - pt) - scale_next;

        if (lowestDistanceChild > distanceChild) {
            lowestDistanceChild = distanceChild;

            // save the subsphere
            dirUp_saved = dirUp_next;
            dirEqPhase_saved = dirEqPhase_next;
            ptO_saved = ptO_next;
        }

        if (iterations == 0) {
            // child 10:
            dirUp_next = normalize(-middleFinger - sqrt(3.) * dirUp);
            ptO_next = ptO + dirUp_next * scale * (4./3.);
            dirEqPhase_next = normalize(- dirUp - 0.5 * sqrt(3.) * dirUp_next);

            distanceChild = length(ptO_next - pt) - scale_next;

            if (lowestDistanceChild > distanceChild) {
                lowestDistanceChild = distanceChild;

                // save the subsphere
                dirUp_saved = dirUp_next;
                dirEqPhase_saved = dirEqPhase_next;
                ptO_saved = ptO_next;
            }
            // child 11:
            dirUp_next = normalize(0.5 * sqrt(3.) * dirEqPhase + 0.5 * middleFinger - sqrt(3.) * dirUp);
            ptO_next = ptO + dirUp_next * scale * (4./3.);
            dirEqPhase_next = normalize(-dirUp - 0.5 * sqrt(3.) * dirUp_next);

            distanceChild = length(ptO_next - pt) - scale_next;

            if (lowestDistanceChild > distanceChild) {
                lowestDistanceChild = distanceChild;

                // save the subsphere
                dirUp_saved = dirUp_next;
                dirEqPhase_saved = dirEqPhase_next;
                ptO_saved = ptO_next;
            }
            // child 12:
            dirUp_next = normalize(- 0.5 * sqrt(3.) * dirEqPhase + 0.5 * middleFinger - sqrt(3.) * dirUp);
            ptO_next = ptO + dirUp_next * scale * (4./3.);
            dirEqPhase_next = normalize (-dirUp - 0.5 * sqrt(3.) * dirUp_next);

            distanceChild = length(ptO_next - pt) - scale_next;

            if (lowestDistanceChild > distanceChild) {
                lowestDistanceChild = distanceChild;

                // save the subsphere
                dirUp_saved = dirUp_next;
                dirEqPhase_saved = dirEqPhase_next;
                ptO_saved = ptO_next;
            }

        }

        if (lowestDistanceChild < lowestDistance) {
            chosenIteration = iterations;
            lowestDistance = lowestDistanceChild;
        } else if (lowestDistanceChild - lowestDistance > 0.5 * scale - scale_next) {
            break;
        }

        dirUp = dirUp_saved;
        dirEqPhase = dirEqPhase_saved;
        ptO = ptO_saved;

        iterations++;
        scale = scale_next;
        middleFinger = normalize(cross(dirUp, dirEqPhase));

    }
    // Each color is a sine-wave with a period of one. Red/Green/Blue have different peaks to ensure each colour is interesting
    return vec4(lowestDistance, vec3(
        sin((-float(chosenIteration) * 0.1 - 0.25 + time*0.1) * 2.*PI) * 0.5 + 0.5,
        sin((-float(chosenIteration) * 0.1 - 0.25 + 0.33 + time*0.1) * 2.*PI) * 0.5 + 0.5,
        sin((-float(chosenIteration) * 0.1 - 0.25 + 0.66+ time*0.1) * 2.*PI) * 0.5 + 0.5
    ));
}

vec4 map(in vec3 pos)
{

    // rotation around y axis over time
    float rotAngle1 = time*0.15;
    float rotAngle2 = time*0.2;
    mat2 rotMatrix1 = mat2(
    vec2(cos(rotAngle1),-sin(rotAngle1)),
    vec2(sin(rotAngle1),cos(rotAngle1))
    );
    mat2 rotMatrix2 = mat2(
    vec2(cos(rotAngle2),-sin(rotAngle2)),
    vec2(sin(rotAngle2),cos(rotAngle2))
    );
    pos.xz = pos.xz * rotMatrix1;
    pos.xy = pos.xy * rotMatrix2;

    return //min(
    //sdfGround(pos, -1.),
    sdfSphereFlake(pos, 0.2)
    //)
    ;
}
// calc surface normal... or gradient ascent vector
// The reason we go for gradient ascent instead of gradient descent is that at the surface of an SDF defined object,
// the surface normal should point outside of the object, and not inside (for lighting purposes)
vec3 calcNormal(in vec3 pt) {
    // this constant determines the size of the area over which the gradient is determined
    // and it's a vector because it's easy to transform into VAL,0,0  or 0,VAL,0 or 0,0,VAL as seen below
    vec2 epsilon = vec2(0.000001,0.0);
    // over each axis the gradient descent vector should be positive if lower values
    return normalize(vec3(
    map(pt + epsilon.xyy).x - map(pt - epsilon.xyy).x,
    map(pt + epsilon.yxy).x - map(pt - epsilon.yxy).x,
    map(pt + epsilon.yyx).x - map(pt - epsilon.yyx).x
    ));
}

vec3 getColour(in vec3 surfacePoint) {
    // sun direction here is direction to sun, not direction from sun
    vec3 sunDir = normalize(vec3(0.8,0.4,0.2));
    vec3 surfaceNormal = calcNormal(surfacePoint);

    vec3 UP = vec3(0., 1., 0.);

    vec3 baseColour = map(surfacePoint).yzw;
    vec3 skyColour = vec3(0.6,0.93,1.0);

    // Here we assume sunlight is not coloured
    float sunPart = clamp(dot(surfaceNormal, sunDir), 0., 1.);
    float skyPart = clamp(0.5 + 0.5 * dot(surfaceNormal, UP), 0., 1.);

    return sunPart * baseColour + 0.3 * skyPart * skyColour;
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    // ray origin (where the camera is)
    vec3 rayOrigin = vec3(0.0, sin(0.2*time) * 0.2, 1.4);
    // ray direction (in the cone of the camera we make sure the ray passes through the pixels of the viewport at some distance away from the ray)
    // it is negative because the camera looks in the opposite direction of where it is placed (i.e. it faces the origin)
    vec3 rayDirection = normalize(vec3(p,(-5.1 - 1.4 * sin(0.3 * time))));

    // ray marching
    float minDist = 0.2;
    float distanceMarched=minDist;
    float maxDist =100.0;
    vec3 rayEnd;
    for (int i = 0; i<90; i++) {
        rayEnd = rayOrigin + distanceMarched * rayDirection;

        float distanceToNearest = map(rayEnd).x;
        if (distanceToNearest<0.0002)
        break;

        distanceMarched += distanceToNearest;
        // max distance we march the ray... we don't care for points beyond.

        if (distanceMarched > maxDist) break;
    }
    vec3 col;
    if (distanceMarched<maxDist) {
        // object
        col = getColour(rayEnd);
    } else {
        // background
        col = vec3(.1,.2,.4);
    }

    glFragColor = vec4(col,1.0);
}
