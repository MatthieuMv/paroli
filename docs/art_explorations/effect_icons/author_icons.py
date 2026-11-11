#!/usr/bin/env python3
"""Author the review SVG set from explicit vector drawings; no runtime generation is needed.

Run from any directory. Emitted SVGs are standalone, editable source assets.
Shared primitives keep outlines/pips consistent, while each effect owns its composition.
"""
from pathlib import Path
from html import escape
import json

ROOT = Path(__file__).resolve().parent
INK = '#30223d'
CREAM = '#f4eddc'
MINT = '#93b99b'
LIME = '#bed17d'
GOLD = '#edcc63'
HONEY = '#dcb34e'
PEACH = '#f48665'
PINK = '#f29fbe'
RED = '#e77984'
PURPLE = '#b7a3d7'
DEEP = '#929cdd'
BLUE = '#8bbfdf'
TEAL = '#68bbb2'
BROWN = '#bc9683'
ORANGE = '#efa05b'


def path(d, fill='none', stroke=INK, w=14, extra=''):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'


def rect(x, y, width, height, fill, radius=18, w=14, stroke=INK):
    return f'<rect x="{x}" y="{y}" width="{width}" height="{height}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="{w}"/>'


def oval(x, y, rx, ry, fill, w=14, stroke=INK):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{w}"/>'


def circle(x, y, r, fill, w=14, stroke=INK):
    return oval(x,y,r,r,fill,w,stroke)


def group(body, transform):
    return f'<g transform="{transform}">{body}</g>'


def star(x, y, size=30, fill=GOLD):
    return path(f'M{x} {y-size} l{size*.28} {size*.72} {size*.72} {size*.28} {-size*.72} {size*.28} {-size*.28} {size*.72} {-size*.28} {-size*.72} {-size*.72} {-size*.28} {size*.72} {-size*.28}Z',fill,w=8)


def heart(x,y,size=70,fill=RED):
    return group(path('M0 18C-48-10-46-46-19-46-7-46 0-36 0-36S7-46 19-46C46-46 48-10 0 18Z',fill,w=7),f'translate({x} {y}) scale({size/70})')


def die(x,y,size=100,value=1,color=CREAM,angle=0):
    spots={1:[(50,50)],2:[(32,32),(68,68)],3:[(30,30),(50,50),(70,70)],4:[(30,30),(70,30),(30,70),(70,70)],5:[(30,30),(70,30),(50,50),(30,70),(70,70)],6:[(30,28),(70,28),(30,50),(70,50),(30,72),(70,72)]}
    body=rect(5,15,90,90,BROWN,18,7)+rect(5,5,90,90,color,18,7)
    # Icon dice use flat faces: no shine strokes, including small curved glints.
    body+=''.join(circle(px,py,7,INK,0) for px,py in spots[value])
    return group(body,f'translate({x} {y}) scale({size/100}) rotate({angle} 50 50)')


def coin(x,y,r=45):
    return circle(x+7,y+8,r,HONEY,9)+circle(x,y,r,GOLD,9)+path(f'M{x} {y-r*.48}l{r*.3} {r*.48}-{r*.3} {r*.48}-{r*.3}-{r*.48}Z',CREAM,w=5)


def mug(x,y,fill=CREAM,size=1):
    body=path('M52 10H69C94 10 94 52 69 52H54',fill,w=10)+rect(0,0,62,77,fill,13,10)+oval(31,4,31,10,BROWN,7)
    return group(body,f'translate({x} {y}) scale({size})')


def helmet(x,y,size=100,fill=MINT,pips=1):
    body=path('M10 60C10-13 90-13 90 60Z',fill,w=8)+path('M48 5V57',stroke=CREAM,w=5)+rect(3,57,94,20,fill,8,8)
    body+=circle(50,41,15,CREAM,5)
    if pips==1:body+=circle(50,41,5,INK,0)
    else:body+=circle(44,41,4,INK,0)+circle(56,41,4,INK,0)
    return group(body,f'translate({x} {y}) scale({size/100})')


def duck(x,y,size=100,fill=GOLD):
    body=path('M13 48C-1 82 15 99 52 94 85 89 98 70 96 59L76 67 68 42C89 6 44-10 36 16 31 28 39 37 45 42Z',fill,w=8)+path('M33 23 12 29 35 36Z',ORANGE,w=5)+circle(47,20,4,INK,0)+path('M42 65Q56 81 72 67',stroke=HONEY,w=6)
    return group(body,f'translate({x} {y}) scale({size/100})')


def bowl_bird(x,y,fill,mirror=False):
    body=oval(0,0,59,77,fill,10)+path('M-16 2Q-43 48-9 48',stroke=INK,w=7)+circle(17,-28,6,INK,0)+path('M46-20 74-9 47 1Z',GOLD,w=7)+path('M-20 72V91M4 75V91',w=8)
    return group(body,f'translate({x} {y}) scale({-1 if mirror else 1} 1)')


def draw(id):
    """Each branch is an intentionally composed icon, not a recolored generic badge."""
    if id=='solo_talent':
        return oval(256,381,170,43,DEEP)+path('M149 367 133 122Q255 86 379 122L363 367Q256 400 149 367Z',PURPLE)+oval(256,123,123,31,PURPLE)+path('M146 293Q256 324 368 293L363 343Q256 377 149 343Z',GOLD)
    if id=='pair_partner':
        sock=path('M40 0H139V158L87 224C67 250 10 245-5 216-19 190-3 169 29 143Z',MINT,w=11)+rect(34,-5,112,40,CREAM,8,10)
        return group(sock,'translate(102 123) rotate(13 65 100)')+group(sock,'translate(278 129) rotate(-12 65 100)')+heart(266,105,45,PINK)
    if id=='double_partner':
        shape=die(0,0,240,2,PURPLE,-8)
        return '<g opacity="0.42">'+group(shape,'translate(103 126)')+'</g>'+group(shape,'translate(171 167)')
    if id=='triple_bond':
        body=path('M67 286Q257 149 444 242Q416 383 258 405Q133 417 67 286Z',MINT)
        body+=path('M78 278Q251 161 438 244Q323 316 78 278Z',TEAL,w=10)
        for x,y in [(154,255),(253,234),(351,235)]:
            body+=circle(x,y,49,LIME,10)+circle(x-14,y-5,5,INK,0)+circle(x+14,y-5,5,INK,0)+path(f'M{x-10} {y+15}Q{x} {y+25} {x+10} {y+15}',w=5)
        return body+path('M72 285Q241 366 440 244',stroke=MINT,w=20)+path('M435 245Q461 208 432 182',w=10)
    if id=='sure_footing':
        body=rect(91,104,330,304,CREAM,29,12)
        # A long dotted detour contrasts with the direct diagonal shortcut.
        body+=path('M148 340V167H362',stroke=BROWN,w=12,extra='stroke-dasharray="15 25"')
        body+=path('M153 338 342 191',stroke=INK,w=29)+path('M153 338 342 191',stroke=TEAL,w=15)
        body+=path('M290 187 360 178 345 246',stroke=INK,w=27)+path('M290 187 360 178 345 246',stroke=TEAL,w=14)
        return body+circle(148,342,18,GOLD,9)
    if id=='house_guest':
        return path('M128 365V401M384 365V401',w=18)+rect(104,161,304,194,PURPLE,48)+die(204,168,108,2,CREAM,-9)+rect(105,284,302,87,DEEP,24)+rect(78,232,73,137,PURPLE,28)+rect(361,232,73,137,PURPLE,28)
    if id=='last_mile':
        flag=path('M140 108C237 61 298 169 406 123V301C298 348 237 241 140 287Z',CREAM)
        flag+=path('M140 108Q183 87 229 110V170Q183 148 140 169ZM229 170Q272 193 318 188V248Q272 253 229 230ZM318 128Q364 144 406 123V183Q364 204 318 188ZM140 229Q183 208 229 230V288Q183 266 140 287ZM318 248Q364 263 406 243V301Q364 322 318 307Z',INK,w=0)
        return flag+path('M135 88V426',stroke=INK,w=18)+circle(135,82,17,GOLD,8)
    if id=='four_together':
        body=path('M256 260Q330 387 281 455',stroke=INK,w=26)+path('M256 260Q330 387 281 455',stroke=MINT,w=13)
        leaf=path('M256 258C239 222 173 203 173 151C173 107 226 91 256 129C286 91 339 107 339 151C339 203 273 222 256 258Z',MINT,w=12)
        for angle in [0,90,180,270]:
            body+=group(leaf,f'rotate({angle} 256 258)')
        return body+circle(256,258,15,LIME,7)
    if id=='family_bond':
        return path('M165 363 105 273Q83 236 107 222Q129 211 164 263V128Q164 100 185 100Q206 100 206 128V216V83Q206 56 229 56Q252 56 252 83V215V101Q252 74 275 74Q298 74 298 101V224V144Q298 118 321 118Q344 118 344 144V285Q344 329 316 363L311 409Q255 443 174 409Z',GOLD)+path('M182 380Q250 403 311 380M207 270Q246 250 283 273',w=9)
    if id=='family_spirit':
        cat=path('M-65 2-70-67-28-40Q0-51 28-40L70-67 65 2Q62 65 0 65Q-62 65-65 2Z',ORANGE,w=9)+path('M-38-3Q-26-16-14-3M14-3Q26-16 38-3M-8 16 0 23 8 16M0 23Q-12 39-25 28M0 23Q12 39 25 28',w=6)
        return path('M256 359V414M198 418H314',stroke=INK,w=15)+oval(256,225,131,156,PURPLE,13)+oval(256,225,109,133,BLUE,8)+group(cat,'translate(256 234) scale(1.1)')+path('M176 169Q187 126 215 118',stroke=CREAM,w=9)
    if id=='one_or_nothing':
        return die(144,206,225,1,CREAM,-6)+path('M169 192 137 104 211 130 256 67 296 132 376 106 344 196Z',GOLD)+path('M177 181 337 181',w=9)+circle(256,143,15,RED,7)
    if id=='six_addict':
        body=die(139,160,243,6,PEACH,-6)
        return body+heart(124,137,64,PINK)+heart(387,151,64,RED)+heart(391,376,44,PINK)
    if id in ['odd_charm','even_charm']:
        body=circle(264,277,159,DEEP)+circle(250,251,159,PURPLE)+circle(250,251,124,PURPLE,7,CREAM)
        points=[(250,195),(203,285),(297,285)] if id=='odd_charm' else [(207,208),(293,208),(207,294),(293,294)]
        body+=''.join(circle(x,y,25,INK,0) for x,y in points)
        return body
    if id=='lucky_seven':
        return path('M128 112 187 132 168 241Q163 328 253 337 341 326 336 241L317 132 378 112 403 242Q419 406 254 423 86 406 103 242Z',HONEY)+path('M128 97 187 117 168 226Q163 313 253 322 341 311 336 226L317 117 378 97 403 227Q419 391 254 408 86 391 103 227Z',GOLD)+''.join(circle(x,y,9,INK,0) for x,y in [(143,184),(137,264),(169,337),(340,337),(372,264),(368,184),(254,366)])+path('M228 169H283L248 245',stroke=INK,w=20)
    if id=='unique':
        # A side-on lamb: four stubby legs, a scalloped fleece, and one drooping ear.
        body=path('M153 319V382H176V327M205 331V387H228V334M279 329V384H302V323',INK,w=12)
        body+=path('M115 255Q83 226 108 201Q114 181 142 184Q134 147 168 140Q191 133 209 152Q229 121 258 139Q284 143 287 168Q320 157 336 186Q358 205 339 232Q369 254 351 281Q343 308 314 304Q308 336 276 330Q252 352 228 331Q200 351 180 327Q150 339 135 314Q107 317 100 291Q91 269 115 255Z',INK,w=10)
        body+=path('M309 204Q326 174 355 187Q384 198 383 229L408 256Q419 273 401 287Q382 300 347 290Q318 283 317 253Z',CREAM,w=11)
        body+=path('M329 210Q297 193 294 218Q292 241 319 241Z',CREAM,w=9)
        body+=path('M350 235Q360 245 370 235',w=7)+circle(402,263,4,INK,0)
        return body+path('M381 280Q392 285 400 279',w=6)
    if id=='small_circle':
        return path('M138 371 127 419M364 371 375 419',w=21)+rect(129,119,254,226,PEACH,76)+rect(107,280,298,106,ORANGE,33)+rect(88,231,89,142,PEACH,35)+rect(337,231,89,142,PEACH,35)+die(200,178,114,1,CREAM,8)+mug(354,202,CREAM,.65)+path('M169 322H343',w=9)
    if id=='squad':
        return path('M102 265 139 184Q152 163 178 163H312Q340 163 356 190L397 264Z',MINT)+path('M179 184H242V258H148ZM263 184H310Q320 184 332 205L357 258H263Z',BLUE,w=10)+rect(82,254,350,106,MINT,30)+path('M100 310H414',stroke=CREAM,w=16)+circle(160,354,49,INK,9)+circle(354,354,49,INK,9)+circle(160,354,24,HONEY,7)+circle(354,354,24,HONEY,7)+rect(388,275,24,25,GOLD,7,6)
    if id=='quiet_strength':
        # Compact horizontal battery: one clear terminal and three uncluttered charge cells.
        body=rect(389,220,37,72,HONEY,10,11)+rect(86,166,313,180,CREAM,29,13)
        for x in [111,203,295]:
            body+=rect(x,190,76,132,MINT,13,0)
        return body
    if id=='pocket_money':
        body=''
        for x,y in [(140,342),(259,365),(365,300)]:
            for offset in [34,17,0]:
                body+=oval(x,y+offset,62,24,HONEY,9)
            body+=oval(x,y,62,24,GOLD,9)+path(f'M{x-13} {y}H{x+13}',stroke=CREAM,w=7)
        return body+coin(210,208,70)+coin(341,137,53)+star(113,122,24,GOLD)
    if id=='paid_leave':
        # A compact three-quarter chair leaves equal visual weight to the larger sun.
        body=path('M157 330 129 417M250 307 231 390M284 356 322 421M369 345 400 392',stroke=INK,w=15)
        body+=path('M157 330 129 417M250 307 231 390M284 356 322 421M369 345 400 392',stroke=BROWN,w=7)
        body+=path('M105 232 205 207 274 317 177 346Z',CREAM,w=11)
        body+=path('M132 225 158 218 228 331 203 338Z',TEAL,w=0)
        body+=path('M177 346 274 317 379 344 280 378Z',TEAL,w=11)
        body+=path('M105 232 177 346 280 378M205 207 274 317 379 344',stroke=INK,w=13)
        body+=circle(339,128,58,GOLD,10)
        for d in ['M339 47V31','M339 209V225','M258 128H242','M420 128H436','M282 71 270 59','M396 185 408 197','M396 71 408 59','M282 185 270 197']:
            body+=path(d,stroke=HONEY,w=10)
        return body
    if id=='rolling_income':
        return path('M196 177V135Q196 114 218 114H295Q316 114 316 135V177',stroke=INK,w=18)+rect(88,177,336,228,TEAL,28)+path('M89 244Q255 316 424 244',w=11)+rect(234,266,44,50,GOLD,9,9)+coin(364,361,66)
    if id=='extremities':
        # A striped border barrier between two substantial posts.
        body=rect(102,253,52,153,TEAL,12,12)+rect(358,253,52,153,TEAL,12,12)
        body+=rect(75,213,362,61,CREAM,12,12)
        for x in [117,202,287,372]:
            body+=path(f'M{x} 219l-29 49h30l29-49Z',RED,w=0)
        body+=circle(128,243,9,INK,0)+circle(384,243,9,INK,0)
        return body+path('M111 407H145M367 407H401',w=16)+path('M256 113V173M236 153 256 175 276 153',stroke=INK,w=11)
    if id=='neighbours':
        return path('M105 287Q87 278 87 307V340Q88 363 114 375L231 429Q255 441 281 426L410 361Q434 348 425 320L412 294Z',HONEY)+path('M95 297 249 220 422 298Q438 311 413 325L281 395Q254 409 228 394L103 331Q80 318 95 297Z',LIME,w=11)+path('M102 278 251 202 416 279Q435 290 414 305L277 375Q254 387 231 376L101 311Q80 297 102 278Z',RED,w=10)+path('M104 216 224 144Q253 125 284 143L410 213Q447 235 420 260L285 337Q256 354 227 338L94 264Q69 242 104 216Z',CREAM)+path('M93 256 229 331Q257 347 284 332L422 254',stroke=BROWN,w=13)+path('M179 219 192 212M251 179 264 172M314 231 327 224',stroke=HONEY,w=9)
    if id=='first_instinct':
        return path('M277 93Q291 78 305 86Q316 92 310 109L280 207H357Q379 207 365 226L218 410Q205 428 193 419Q183 414 189 395L216 290H144Q120 290 135 271Z',GOLD,w=13)+star(379,127,24,PINK)+star(108,362,19,CREAM)
    if id=='persistence':
        body=rect(74,139,364,248,CREAM,27)+path('M75 209H437V165Q437 139 411 139H101Q75 139 75 165Z',MINT,w=10)
        for x in [137,256,375]:
            body+=circle(x,287,37,CREAM,7,BROWN)
        for x in [137,256]:
            body+=path(f'M{x-19} 286l14 16 26-35',stroke=TEAL,w=13)
        body+=heart(375,300,36,PINK)
        return group(body,'rotate(-7 256 256)')
    if id=='opening_act':
        return rect(84,96,344,316,DEEP,14)+path('M86 109H254Q239 240 153 288L125 405H84ZM426 109H258Q273 240 359 288L387 405H428Z',RED)+path('M133 116Q143 214 113 269M182 117Q185 212 151 267M379 116Q369 214 399 269M330 117Q327 212 361 267',stroke=PEACH,w=9)+path('M114 275 164 289M348 289 398 275',stroke=GOLD,w=17)+path('M73 96H439',stroke=INK,w=24)
    if id=='grand_finale':
        # Reference-inspired party popper: diagonal striped cone, open rim, curling confetti.
        cone='M66 437Q58 449 72 445L355 355 145 155Z'
        body='<defs><clipPath id="cone"><path d="'+cone+'"/></clipPath></defs>'
        body+=path(cone,GOLD,w=12)
        body+='<g clip-path="url(#cone)">'+path('M111 220Q167 323 300 389',stroke=RED,w=48)+path('M65 345Q97 397 168 435',stroke=DEEP,w=39)+'</g>'
        body+=path(cone,w=12)
        body+=path('M145 155Q207 174 269 237Q331 299 355 355Q294 337 230 273Q166 209 145 155Z',HONEY,w=9)
        for d,col in [('M211 204Q257 149 227 92',DEEP),('M285 211Q322 199 320 172Q318 143 348 143Q383 143 380 117Q378 103 389 92',GOLD),('M305 293Q353 249 428 282',DEEP),('M325 100Q340 70 326 45',RED)]:
            body+=path(d,stroke=INK,w=18)+path(d,stroke=col,w=10)
        body+=path('M405 204Q435 189 459 204',stroke=RED,w=12)
        body+=path('M193 119 181 107M282 144H293M393 314 404 325',stroke=TEAL,w=13)
        return body+path('M290 83V95M365 226V240M410 234H422',stroke=RED,w=12)
    if id=='echo':
        # Restore the compact megaphone, including its short handle beneath the rear body.
        return path('M176 278 189 363Q192 374 204 374H230Q239 374 236 362L222 282Z',HONEY)+path('M121 244 309 139V360L121 294Z',PEACH)+oval(309,249,52,111,ORANGE)+oval(309,249,29,73,INK,8)+rect(84,236,66,66,CREAM,16)+path('M382 193Q414 246 382 302M419 162Q469 249 419 332',stroke=TEAL,w=13)
    if id=='solo_act':
        # A matte die anchors the surrounding musical notes; no instruments or shine.
        body=die(174,176,164,1,CREAM,-6)
        for x,y,scale,col in [(94,105,.75,PURPLE),(334,104,.75,TEAL),(100,323,.7,PEACH),(334,322,.7,GOLD)]:
            note=path('M20 100V12L91 0V88',stroke=INK,w=12)+path('M20 30 91 18',stroke=INK,w=12)+oval(5,104,22,16,col,9)+oval(76,92,22,16,col,9)
            body+=group(note,f'translate({x} {y}) scale({scale})')
        return body
    if id=='better_together':
        # Perched parakeets: a round crown, hooked beak, long tail and only the two joined wings.
        body=path('M90 382H422',stroke=BROWN,w=16)
        bird=path('M-22 79-43 145-6 122 9 75Z',PEACH,w=10)
        bird+=path('M-9 98V124M17 98V124',w=7)
        bird+=path('M-48 30V-45C-48-99 32-110 49-65Q60-43 46-19Q65 15 56 54Q47 99 5 102Q-45 101-48 57Z',PEACH,w=11)
        bird+=path('M46-58Q75-60 77-40L56-26Q62-43 46-42Z',GOLD,w=7)
        bird+=circle(29,-63,6,INK,0)
        body+=group(bird,'translate(164 257)')+group(bird.replace(PEACH,MINT),'translate(348 257) scale(-1 1)')
        body+=path('M208 272Q232 271 256 291Q237 305 217 294Z',PEACH,w=8)+path('M304 272Q280 271 256 291Q275 305 295 294Z',MINT,w=8)
        return body+heart(256,132,58,RED)
    if id=='double_date':
        return path('M198 310 158 424M314 310 354 424',w=19)+oval(256,282,166,77,BROWN)+oval(256,261,166,77,CREAM)+mug(168,176,PEACH,.65)+mug(292,176,PEACH,.65)+mug(168,244,MINT,.65)+mug(292,244,MINT,.65)+heart(256,106,48,RED)
    if id=='three_company':
        body=die(80,223,162,3,PEACH,-10)+die(272,223,162,3,MINT,10)+die(176,104,162,3,PURPLE)
        return body
    if id=='short_journey':
        body=path('M126 357 116 385M220 358 210 386M317 326 317 360M402 281 422 300',w=16)
        for x,y,r,fill in [(127,296,56,MINT),(220,289,59,LIME),(310,255,64,MINT),(385,200,72,LIME)]:body+=circle(x,y,r,fill)
        body+=path('M357 135 341 98M408 131 427 92',w=10)+circle(339,89,13,GOLD,8)+circle(433,83,13,GOLD,8)+circle(367,187,8,INK,0)+circle(408,182,8,INK,0)+path('M372 216Q391 233 410 209',w=8)
        return body
    if id=='open_house':
        body=rect(79,164,354,238,DEEP,50)+rect(79,141,354,238,CREAM,50)+rect(101,164,310,188,BLUE,32,8)
        for x,fill in [(140,PEACH),(198,MINT),(256,GOLD),(314,PURPLE),(372,PEACH)]:
            body+=path(f'M{x} 295C{x-25} 267 {x-23} 194 {x} 184C{x+23} 194 {x+25} 267 {x} 295L{x-18} 329H{x+18}Z',fill,w=7)+circle(x+5,209,5,INK,0)
        body+=path('M88 154Q93 91 146 91H362Q415 91 424 154Z',BROWN,w=11)+path('M118 133Q133 112 158 112H354Q380 112 394 133',stroke=CREAM,w=8)+oval(256,121,32,14,HONEY,7)
        return body
    if id=='long_journey':
        return rect(79,148,354,216,MINT,49)+path('M81 279H431V334H81Z',CREAM,w=9)+rect(105,180,101,74,BLUE,16,9)+rect(234,180,71,163,TEAL,13,9)+rect(333,180,70,74,BLUE,15,9)+circle(151,365,43,INK,8)+circle(371,365,43,INK,8)+circle(151,365,12,CREAM,0)+circle(371,365,12,CREAM,0)+circle(288,270,5,CREAM,0)
    if id=='four_corners':
        body=rect(112,112,288,288,CREAM,32,12)
        for x,y,angle,col in [(112,112,0,PEACH),(400,112,90,MINT),(400,400,180,PURPLE),(112,400,270,GOLD)]:
            corner=path('M0 93V24Q0 0 24 0H93V37H37V93Z',col,w=10)
            body+=group(corner,f'translate({x} {y}) rotate({angle})')
        return body+die(202,202,108,4,CREAM)
    if id=='family_reunion':
        body=rect(70,96,372,323,BROWN,19)+rect(93,118,326,276,CREAM,9,9)
        for x,y in [(161,150),(263,150),(110,264),(212,264),(314,264)]:
            body+=die(x,y,88,5,MINT)
        return body+heart(256,109,35,RED)
    if id=='match_master':
        # The shared heart conveys a match without connecting the dice with a physical cord.
        return die(80,210,164,2,MINT,-10)+die(268,210,164,2,PEACH,10)+heart(256,160,111,RED)
    if id=='bipolarity':
        return path('M207 399Q200 399 207 386L248 293Q257 276 266 294L307 386Q315 399 303 399Z',BROWN,w=10)+path('M82 326 421 214',stroke=INK,w=24)+path('M82 326 421 214',stroke=HONEY,w=12)+die(73,204,112,1,MINT,-15)+die(318,93,112,6,PEACH,-15)+circle(258,285,15,CREAM,7)
    if id=='mathmind':
        body=rect(97,110,317,302,BROWN,18)+rect(124,137,263,248,CREAM,7,8)
        for y in [190,260,330]:body+=path(f'M125 {y}H386',stroke=INK,w=9)
        for x,y,col in [(162,190,MINT),(211,190,MINT),(314,190,PEACH),(160,260,GOLD),(269,260,PURPLE),(319,260,PURPLE),(212,330,PEACH),(261,330,PEACH),(312,330,PEACH)]:body+=oval(x,y,19,31,col,7)+path(f'M{x+3} {y-14}q-11 12 0 27',stroke=INK,w=4)
        return body
    if id in ['odd_squad','even_squad']:
        if id=='odd_squad':return helmet(170,99,170,MINT,1)+helmet(81,279,153,MINT,1)+helmet(278,279,153,MINT,1)
        return helmet(79,107,154,MINT,2)+helmet(279,107,154,MINT,2)+helmet(79,293,154,MINT,2)+helmet(279,293,154,MINT,2)
    if id=='variety_show':
        # Generous twisted wrappers and a spiral lollipop make every sweet recognizable.
        wrapped=path('M-52-24-101-44-88-9-104 24-52 21ZM52-24 101-44 88-9 104 24 52 21Z',PINK,w=10)+rect(-58,-43,116,86,RED,36,11)+path('M-25-38-2 38M7-39 30 35',stroke=CREAM,w=12)
        body=group(wrapped,'translate(158 170) rotate(-18)')
        body+=group(wrapped.replace(PINK,MINT).replace(RED,TEAL),'translate(270 358) rotate(12)')
        body+=path('M366 190 401 278',stroke=INK,w=18)+path('M366 190 401 278',stroke=CREAM,w=8)
        body+=circle(348,137,66,GOLD,11)+path('M310 139Q304 99 345 96Q390 96 387 139Q383 177 347 173Q319 168 328 141Q334 122 351 129Q368 136 353 149',stroke=PEACH,w=13)
        return body
    if id=='less_is_more':
        body=path('M111 208Q92 178 117 164Q138 154 151 169H361Q375 154 395 165Q418 180 400 208V354Q418 385 395 398Q375 410 359 393H151Q137 408 116 396Q94 381 111 354Z',PURPLE,w=13)
        body+=path('M161 279Q186 305 211 279M301 279Q326 305 351 279M234 333Q256 344 278 333',w=11)
        body+=path('M196 176 180 104 228 125 256 84 284 125 332 104 316 176Z',GOLD,w=11)
        return body+path('M368 90H401L371 124H405',stroke=INK,w=9)
    if id=='backup':
        return path('M126 317V398M386 317V398',stroke=INK,w=20)+path('M129 181V314M383 181V314',stroke=INK,w=17)+rect(95,164,322,103,BROWN,18,12)+rect(80,302,352,51,HONEY,16,12)
    if id=='stonks':
        body=path('M106 274 198 177 257 217 351 115 318 84 430 70 417 184 383 151 266 278 206 238 138 311Z',MINT,w=13)
        for x,y in [(141,371),(256,347),(371,319)]:
            body+=coin(x,y,43)
        return body
    if id=='window_shopper':
        body=circle(261,278,167,BROWN)+circle(255,255,167,HONEY)+circle(255,255,140,CREAM,9)
        for i,col in enumerate([RED,INK,RED,INK,MINT,INK,RED,INK]):
            import math
            a=math.radians(i*45);b=math.radians((i+1)*45)
            x1,y1=255+138*math.cos(a),255+138*math.sin(a);x2,y2=255+138*math.cos(b),255+138*math.sin(b)
            body+=path(f'M255 255  {x1:.2f} {y1:.2f} A138 138 0 0 1 {x2:.2f} {y2:.2f}Z',col,CREAM,5)
        return body+circle(255,255,73,HONEY,10)+path('M255 175V335M175 255H335',stroke=INK,w=17)+path('M255 175V335M175 255H335',stroke=GOLD,w=8)+circle(255,255,23,CREAM,8)+circle(346,163,16,CREAM,7)
    if id=='portfolio':
        # A softly rounded savings pouch, tied shut, with one gold coin emblem.
        body=path('M208 190 171 102Q208 119 231 99Q256 118 280 99Q307 118 341 102L305 190Z',BROWN,w=12)
        body+=path('M208 188Q186 231 147 278Q113 322 137 368Q165 417 256 417Q347 417 375 368Q399 322 365 278Q326 231 305 188Z',BROWN,w=13)
        body+=path('M213 217Q200 240 193 267M300 217Q313 240 320 267',stroke=INK,w=8)
        body+=path('M204 189H309',stroke=INK,w=23)+path('M204 189H309',stroke=PURPLE,w=12)
        body+=path('M271 190Q308 150 325 172Q338 192 300 201L323 227M271 190 282 235',stroke=INK,w=10)
        return body+coin(252,325,53)
    if id=='alignment':
        bird=path('M11 63Q3 99 44 106Q91 112 99 70L75 77Q61 70 66 53Q88 35 72 15Q56-4 37 12Q21 25 34 45Q45 57 11 63Z',GOLD,w=7)+path('M36 29 17 34 36 42Z',ORANGE,w=5)+circle(50,26,4,INK,0)+path('M42 77Q56 92 72 79',stroke=HONEY,w=6)
        body=''
        # One diagonal file occupies the full icon; there is no conflicting horizontal baseline.
        for x,y in [(61,79),(159,150),(257,221),(355,292)]:
            body+=group(bird,f'translate({x} {y})')
        return body
    if id=='missing_link':
        # Preserve the user's approved first study exactly.
        return None
    if id=='last_chance':
        # One teardrop with a broad rounded base; no clock or face.
        return path('M256 84C245 130 130 223 130 300C130 373 184 421 256 421C328 421 382 373 382 300C382 223 267 130 256 84Z',BLUE,w=13)+path('M183 284Q183 253 207 228',stroke=CREAM,w=11)
    if id=='extra_time':
        body=circle(256,259,155,TEAL,13)+circle(256,259,128,CREAM,10)
        body+=path('M256 148V163M256 355V370M145 259H160M352 259H367',stroke=BROWN,w=9)+path('M256 179V259L315 290',w=12)
        return body+circle(256,259,12,HONEY,7)
    if id=='second_chance':
        body=path('M119 193Q146 100 247 101Q346 96 397 182',stroke=INK,w=25)+path('M119 193Q146 100 247 101Q346 96 397 182',stroke=MINT,w=13)
        body+=path('M360 177 400 199 416 153',stroke=INK,w=25)+path('M360 177 400 199 416 153',stroke=MINT,w=13)
        body+=path('M395 320Q364 411 265 412Q163 419 114 332',stroke=INK,w=25)+path('M395 320Q364 411 265 412Q163 419 114 332',stroke=MINT,w=13)
        body+=path('M151 337 111 315 95 361',stroke=INK,w=25)+path('M151 337 111 315 95 361',stroke=MINT,w=13)
        return body+die(175,175,162,1,CREAM,-8)
    if id=='momentum':
        return path('M48 223H83M35 277H74M53 331H91',stroke=TEAL,w=10)+path('M105 277Q95 173 177 132Q261 86 341 143Q420 196 402 293Q388 395 280 409Q165 424 119 338Q104 310 105 277Z',CREAM,w=13)+path('M131 320Q196 392 289 369Q363 354 393 287Q388 383 280 398Q176 414 131 320Z',BLUE,w=0)+path('M150 229Q162 178 213 162',stroke=BLUE,w=11)
    if id=='habit':
        return circle(256,267,170,INK,10)+circle(256,256,170,DEEP)+circle(256,256,125,DEEP,7,INK)+circle(256,256,68,PEACH,9)+circle(256,256,15,INK,0)+path('M204 99 228 145 203 190 228 218',stroke=CREAM,w=10)
    if id=='variety':
        mask=path('M-71-76Q0-99 71-76L62 18Q44 76 0 91-44 76-62 18Z',PURPLE,w=10)+path('M-45-21Q-28-41-11-21M11-21Q28-41 45-21M-29 20Q0 55 29 20',w=8)
        second=path('M-71-76Q0-99 71-76L62 18Q44 76 0 91-44 76-62 18Z',PEACH,w=10)+path('M-45-21Q-28-5-11-21M11-21Q28-5 45-21M-29 43Q0 9 29 43',w=8)
        return group(mask,'translate(176 216) rotate(-18)')+group(second,'translate(333 284) rotate(18)')+path('M292 90Q385 105 412 168L422 140M412 168 381 157',stroke=TEAL,w=11)
    raise KeyError(id)


def main():
    items=json.loads((ROOT/'catalog.json').read_text())
    assert len(items)==57
    for item in items:
        destination=ROOT/item['file'];destination.parent.mkdir(exist_ok=True)
        body=draw(item['id'])
        if body is None:
            destination.write_text((ROOT/'missing_link.svg').read_text())
            continue
        title=escape(item['en']+' — '+item['family'])
        desc=escape(item['fr']+'. Paroli icon with chunky plum outlines and a transparent background.')
        destination.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">\n<title>{title}</title>\n<desc>{desc}</desc>\n{body}\n</svg>\n')
    print('Authored 57 standalone SVG icons.')


if __name__=='__main__':main()
