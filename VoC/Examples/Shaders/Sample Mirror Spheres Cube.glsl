#version 420

// original https://www.shadertoy.com/view/wdfXWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//==============================================================================
//    CONFIGURACIÓN
//==============================================================================

//    CFG_USING_ENHANCED_RAYMARCHING utiliza una versión mejorada del algoritmo de trazado de rayos, que implementa
//    las optimizaciones "over-relaxation raymarching" y "screen-space aware intersection point selection" descritas en
//    el paper "Enhanced Sphere Tracing" de Benjamin Kelinert et al. (http://erleuchtet.org/~cupe/permanent/enhanced_sphere_tracing.pdf).
    #define CFG_USING_ENHANCED_RAYMARCHING

//  CFG_USING_DISCONTINUITY_REDUCTION corrige el patrón esférico derivado de la discontinuidad entre el espacio de
//    pantalla (proyección 2D) y el espacio de mundo (posición del rayo y distancia a la superficie). Dicha discontinuidad
//  aparece debido a la proyección del espacio esférico (que tiene profundidad) en el espacio de pantalla.
//    El algoritmo está descrito en el mismo paper "Enhanced Sphere Tracing" indicado anteriormente.
      #define CFG_USING_DISCONTINUITY_REDUCTION

//#define CFG_SHOW_WORLDPOS    // Descomentar para mostrar posiciones en mundo.
//#define CFG_SHOW_NORMALS    // Descomentar para mostrar normales.
//#define CFG_SHOW_STEPS    // Descomentar para mostrar pasos del Raymarcher.
//#define CFG_SHOW_DISTANCE    // Descomentar para mostrar distancias.
//#define CFG_NO_SHADOWS    // Descomentar para desactivar las sombras.
//#define CFG_NO_AO         // Descomentar para desactivar la oclusión ambiental.

const float kNearPlaneDist =   0.1;    // Distancia al plano cercano.
const float kFarPlaneDist  =  50.0;    // Distancia al plano lejano.
const float kEpsilon       = 0.001;    // Valor de epsilon para comparaciones de distancia.
const float kPi               = 3.14159265359;
const int   kMaxSteps      =    64;    // Número máximo de pasos del trazado de rayos.
const int   kMaxLightSteps =    16; // Número máximo de pasos del trazado de rayos de iluminación.

//==============================================================================
//    FUNCIONES DE DISTANCIA
//==============================================================================

//    Primitivas de ejemplo.
//    Otras primitivas disponibles en: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm y
//    http://www.pouet.net/topic.php?which=7931&page=1
float sdPlaneY(vec3 p) { return p.y; }
float sdSphere(vec3 p, float s) { return length(p) - s; }
float sdBox   (vec3 p, vec3  b)
{
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

//    Operadores de ejemplo.
//    Otros operadores disponibles en: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm y
//    http://mercury.sexy/hg_sdf/
float opUnion       (float d1, float d2) { return min( d1, d2); }
float opIntersection(float d1, float d2) { return max( d1, d2); }
float opSubstraction(float d1, float d2) { return max(-d1, d2); }
vec3  opRepetition  (vec3 pos, vec3 frq) { return mod(pos, frq) - 0.5 * frq; } 

//  Smooth minimum (polynomial smin())
//  Ver http://www.iquilezles.org/www/articles/smin/smin.htm para más información.
float opBlend(float d1, float d2, float k) 
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

//==============================================================================
//    ESCENA
//==============================================================================

#define MIN(dst, src) dst = mix(src, dst, step(dst.x, src.x))
vec2 mapScene(vec3 pos)
{
    float t = time * 2.;
    vec2  a = vec2(kFarPlaneDist, 0), b = a;

    float q = abs(sin(time));
   
    b = vec2(sdBox(pos
                   +
                   vec3(
                       sin(pos.y + time),
                       sin(pos.z + time * 2.2),
                       sin(pos.x + time * 3.3)
                       
                       )
                   , vec3(2)), 1.); MIN(a, b);
    float e = b.x;
    b = vec2(
        opBlend(
            opBlend(
                opBlend(
                    sdSphere(opRepetition(pos, vec3(5)), 0.5), 
                    sdBox(opRepetition(pos, vec3(5)), vec3(.1, 5, .1)), q
                    ),
                sdBox(opRepetition(pos, vec3(5)), vec3(5, .1, .1)), q
            ),
            sdBox(opRepetition(pos, vec3(5)), vec3(.1, .1, 5)), q
        ),
        0.);
    MIN(a, b);
    float tt = time * .3;
    for (float i = 0.; i < kPi*2.; i+=kPi*.25)
    {
        b = vec2(
opBlend(            
            sdSphere(pos + vec3(sin(tt+i*2.)*4., cos(tt*3.+i)*4., sin(tt*2.5+i)*3.), 1.0),
         e, 1.)   
            , 1.);
        MIN(a, b);
    }
    /*
    // Creamos una caja para contener la escena.
    b = vec2(opSubstraction(sdBox(pos, vec3(10)), sdBox(pos, vec3(100))), 0); MIN(a, b);
    
    // Calculamos la distancia a 3 esferas unidas entre ellas de forma suave, una centrada y dos orbitando alrededor.
    float p0= opBlend(sdSphere(pos, 1.), sdSphere(pos + 2. * vec3(sin(t*.11), cos(t*.24), cos(t*.33)), 1.), 0.5);
    p0 = opBlend(p0, sdSphere(pos + 1.5 * vec3(cos(t*.21), cos(t*.23), sin(t*.45)), 1.), 0.5);

    // Restamos a dichas esferas un dominio de repetición de cubos en XY e YZ.
    //float p1= sdBox(opRepetition(pos, vec3(.25,0,.25)), vec3(5, 5, .015));
    //p1 = opUnion(p1, sdBox(opRepetition(pos, vec3(.25,0,.25)), vec3(.015, 5, 5)));
    //b  = vec2(opIntersection(p0, p1), 1); MIN(a, b);
    b=vec2(p0,1);MIN(a,b);
    */
    return a;
}

//==============================================================================
//    TRAZADO DE RAYOS
//==============================================================================

//    castRay() traza un rayo con origen en "ro" en dirección "rd" desde el plano cercano kNearPlaneDist 
//  hasta encontrar una superficie contra la que chocar o hasta superar la distancia del plano lejano kFarPlaneDist.
//    El rayo se mueve en pasos discretos hasta un máximo de kMaxSteps (lo que sirve para determinar la precisión).
//    El rayo se desplaza a lo largo de un dominio de distancia: dada una posición en mundo (la del rayo), preguntamos
//    a la función mapScene(), que representa la escena, cuál es la distancia al objeto más cercano. Avanzamos entonces
//    en la dirección del rayo dicha distancia, y volvemos a preguntar hasta que se dé alguna de las condiciones
//    anteriormente indicadas.
//    Entradas:    ro - Origen del rayo.
//                rd - Dirección del rayo.
//    Salida:        vec4(totalDistance, lastStepDistance, materialID, steps). 
#ifndef CFG_USING_ENHANCED_RAYMARCHING
vec4 castRay(vec3 ro, vec3 rd)
{
    float  t   = kNearPlaneDist;
    vec2   res = vec2(kFarPlaneDist, 0);
    int    i   = 0;
    for (; i < kMaxSteps; ++i)
    {
        res    = mapScene(ro + rd * t);
        if ((res.x < kEpsilon) || (t > kFarPlaneDist))
            break;
        t += res.x;
    }
    return vec4(t, res.xy, i);
}
#else// CFG_USING_ENHANCED_RAYMARCHING
vec2  gTexelSize  ; // Pixel size   (screen domain).
float gTexelRadius; // Pixel radius (screen domain).

vec4 castRay(vec3 ro, vec3 rd)
{
    gTexelSize    = 1. / resolution.xy;
    gTexelRadius  = length(gTexelSize) ;
    
    float t   = kNearPlaneDist, stepLength = 0., prevRad = kFarPlaneDist, prevErr = kFarPlaneDist, err, k = 1.2;
    vec2  res = vec2(kFarPlaneDist, 0);
    int   i   = kMaxSteps;
    for (; (i >= 0) && (t < kFarPlaneDist); --i)
    {
        res = mapScene(ro + rd * t);
        bool  sor = (k > 1.) && ((prevRad + res.x) < stepLength);
        if (sor)
        {//    Error detectado, deja de aplicar la optimización "over-relaxation raymarching".
            stepLength-= k * stepLength;
            k = 1.;            
        }        
        else
            stepLength = res.x * k;

        prevRad = res.x;
        err = res.x / t;
        if (!sor)
        {// Actualiza el error.
            if (err < prevErr     ) { res.x = t; prevErr = err; }
            if (err < gTexelRadius) break; // Aplica "screen-space aware intersection point selection".
        }
        t  += stepLength;
    }
    return vec4(t, res.xy, kMaxSteps - i);
}
#endif//CFG_USING_ENHANCED_RAYMARCHING

//==============================================================================
//    UTILIDADES
//==============================================================================

//    Calcula el sombreado para la superficie. Para ello, traza un rayo desde la superficie hasta la luz, y determina
//    si es posible llegar hasta la luz sin encontrar otra superficie antes. Si es posible llegar hasta la luz, el
//    punto estará iluminado. En caso contrario, el punto estará sombreado.
//    Además, para cada paso del rayo computa la distancia mínima al objeto más cercano y utiliza ese valor para calcular
//    la penumbra.
//    Más información sobre el algoritmo en http://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
//    Entradas:    ro   - Posición en mundo de la superficie.
//                rd   - Dirección desde "ro" hasta la luz para la cual queremos calcular el sombreado.
//                tmin - Distancia desde "ro" hasta el inicio del rayo (evita arterfactos por precisión de flotante).
//                tmax - Distancia entre "ro" y la luz (permite descartar cuando llegamos a la luz).
//                k    - Factor de penumbra (cuanto más mayor, la sombra es más dura).
//    Salida:     Factor de sombreado (0 para sombreado, 1 para iluminado, valores intermedios representan penumbra).
#ifndef    CFG_NO_SHADOWS
float computeSoftShadow(vec3 ro, vec3 rd, float tmin, float tmax, float k)
{
    float res = 1.0;
    float ph  = 1e20;
    for( float t = tmin; t < tmax;)
    {
        float h = mapScene(ro + rd*t).x;
        if( h < 0.001)
            return 0.;
        float y = h * h / (2. * ph);
        float d = sqrt(h*h - y*y);
        res = min(res, k*d / max(0.0,t - y));
        ph  = h;
        t  += h;
    }
    return res;
}
#else
float computeSoftShadow(vec3 ro, vec3 rd, float tmin, float tmax, float k) { return 1.0; }
#endif//CFG_NO_SHADOWS

//    Calcula la oclusión ambiental de la superficie. Para ello, muestrea a distintas distancias desde la posición en 
//    mundo para la superficie, y calcula la oclusión ambiental aplicando un filtro de paso bajo: los valores de
//  distancia obtenidos más cercanos a la superficie tienen más peso, y a medida que nos alejamos tienen menos.
//    El proceso que se sigue es el siguiente:
//        - Para cada iteración, calcula una posición en mundo alejada de la superficie 1/N del total de muestras.
//        - Calcula la distancia desde esa posición a la superficie más cercana.
//        - Cuanto más cercana sea esa distancia a la distancia original entre la superficie de entrada y la calculada
//          en la iteración actual, menos oclusión hay.
//    Entradas:    pos    - Posición en mundo para la superficie.
//                nor - Normal de la superficie.
//    Salida:        Factor de oclusión (0 para totalmente ocluido, 1 para totalmente visible).
#ifndef CFG_NO_AO
float computeAO(vec3 pos, vec3 nor)
{
    float  occ = 0.0;
    float  sca = 1.0;
    for( int i = 0; i < 5; ++i)
    {
        float hr = 0.01 + 0.12 * float(i) / 4.0;
        vec3  aopos = nor * hr + pos;
        float dd = mapScene(aopos).x;
        occ += -(dd - hr) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0*occ, 0.0, 1.0);    
}
#else
float computeAO(vec3 pos, vec3 nor) { return 1.0; }
#endif//CFG_NO_AO

//  Calcula la normal de la superficie en "pos" mediante derivación del gradiente de la función de distancia.
//    Entradas:    pos - Posición en mundo de la superficie.
//    Salida:        Vector normal de la superficie.
vec3 computeNormal(vec3 pos)
{
    vec3 epsilon = vec3(kEpsilon, 0, 0);
    return normalize(vec3(mapScene(pos + epsilon.xyy).x - mapScene(pos - epsilon.xyy).x, mapScene(pos + epsilon.yxy).x - mapScene(pos - epsilon.yxy).x, 
        mapScene(pos + epsilon.yyx).x - mapScene(pos - epsilon.yyx).x));
}

//    computeCameraMatrix() calcula la matriz de cámara.
//    Entradas:    ro - Posición de la cámara (eye).
//                ta - Posición en mundo a la que mira la cámara (lookAt).
//                cr - Rotación del vector front, de 0 a 2*π radianes.
//    Salida:        Matriz de cámara.
mat3 computeCameraMatrix(vec3 ro, vec3 ta, float cr)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3 (sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw,cp));
    vec3 cv = normalize(cross(cu,cw));
    return mat3(cu, cv, cw);
}

//    Materiales, luces y colores.
vec3[] gMaterials  = vec3[](vec3(1, 0, 0), vec3( 1, 1,.9));
vec3[] gLightPos   = vec3[](vec3(4, 4, 4), vec3(-4, 4,-4));
vec3[] gLightCol   = vec3[](vec3(1,.9,.5), vec3(.5,.9, 1));
vec3   gAmbientCol = vec3(.1,.2,.3);

//    computeShading() calcula la iluminación con difusa de Lambert y especular de Blinn-Phong.
//    Entradas:    pos - Posición en mundo de la superficie.
//                nor - Normal de la superficie.
//                viewVector - Vector vista.
//                matID      - Índice de material en gMaterials.
//                lightID    - Índice de luz en gLightPos y gLightCol.
//  Salida:        Color resultante.
vec3 computeShading(vec3 pos, vec3 nor, vec3 viewVector, int matID, int lightID)
{
    vec3  col = vec3(0), halfVec  = normalize(-viewVector + normalize(gLightPos[lightID] - pos));
    col = col + gLightCol[lightID] * gMaterials[matID] * clamp(dot(nor, -viewVector), 0., 1.); // Cálculo de difusa.
    col = col + gLightCol[lightID] * pow(clamp(dot(nor, halfVec), 0., 1.), 5.); // Cálculo de especular.
    return     col;
}

//==============================================================================
//    ENTRYPOINT
//==============================================================================

//  Función principal.
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy; // Coordenadas UV en el rango [0,1].
    vec2 p  = (-resolution.xy + 2.0 * gl_FragCoord.xy) / resolution.y; // Coordenadas UV en el rango [0,1] con Aspect Ratio aplicado.
    
    vec3 pos, nor, col; // Posición, normal, color.
    vec4 res; // Resultados del trazado de rayos.

    // Configura la cámara.
    vec3 ro = vec3(sin(time * .35) * 5. * (4. + sin(time)), 5., cos(time * .35) * 5. * (3. + cos(time)));
    vec3 ta = vec3(0);
    mat3 ca = computeCameraMatrix(ro, ta, 0.0);
    vec3 rd = ca * normalize(vec3(p.xy,  2.0));
    
    // Traza el rayo y calcula la posición en mundo de la superficie impactada.
    res = castRay(ro, rd);
    pos = ro + rd * res.x;    
    
#    ifdef   CFG_USING_DISCONTINUITY_REDUCTION
      // Aplica la optimización "discontinuity reduction" para mejorar la adaptación del espacio esférico al de pantalla.
    float coneSize  = tan(kPi / 6.) / (resolution.y);
    float error     = 0.;
    for (int  i = 0; i < 3; ++i)
    {
        pos    -= rd *    (error - mapScene(pos).x);
        error   = coneSize * length(ro  - pos);
    }
#    endif//    CFG_USING_DISCONTINUITY_REDUCTION

    // Calcula la normal.
    nor = computeNormal(pos);
    
    // Para cada luz, computa la iluminación y el sombreado.
    for (int i = 0; i < gLightPos.length(); ++i)
    {
        col+= computeShading(pos, nor, rd, int(res.z), i) * computeSoftShadow(pos, normalize(gLightPos[i] - pos), .025, length(gLightPos[i] - pos), 25.);
    }
    
    float dist = res.x;
    if (res.z == 1.)
    {
        ro = pos + nor * .1;
        rd = reflect(rd, nor);

        res = castRay(ro, rd);
        pos = ro + rd * res.x;    
        nor = computeNormal(pos);
vec3 col2 = vec3(0);
        for (int i = 0; i < gLightPos.length(); ++i)
        {
            col2+= computeShading(pos, nor, rd, int(res.z), i) * computeSoftShadow(pos, normalize(gLightPos[i] - pos), .025, length(gLightPos[i] - pos), 25.);
        }
        col=mix(col,col2,abs(sin(time)));
    }
    
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    col = col + gAmbientCol * gMaterials[int(res.z)] * mix(computeAO(pos, nor), 1., dot(col, W));

#   ifdef   CFG_SHOW_WORLDPOS
    col = pos;
#   endif// CFG_SHOW_WORLDPOS

#   ifdef   CFG_SHOW_NORMALS
    col = nor;
#   endif// CFG_SHOW_NORMALS

#   ifdef   CFG_SHOW_STEPS
    col = mix(vec3(0, 1, 0), vec3(1, 0, 0), res.w / float(kMaxSteps));
#   endif// CFG_SHOW_STEPS

#   ifdef   CFG_SHOW_DISTANCE
    col = vec3(res.x / (kFarPlaneDist - kNearPlaneDist));
#   endif// CFG_SHOW_DISTANCE
    
    col = mix(col, vec3(.3), pow(dist/50.0,.5));
    glFragColor = vec4(col, 1.0);
}
