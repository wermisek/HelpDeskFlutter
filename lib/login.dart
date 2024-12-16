import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_problem_page.dart';
import 'admin_home_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


void main() {
  runApp(MyApp());
}


final String base64Image = "data:image/jpeg;base64,/9j/4QAiRXhpZgAATU0AKgAAAAgAAQESAAMAAAABAAEAAAAAAAD/4AAQSkZJRgABAQEBLAEsAAD/4gHYSUNDX1BST0ZJTEUAAQEAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADb/2wBDAAEBAQEBAQEBAQEBAQEBAQIBAQEBAQIBAQECAgICAgICAgIDAwQDAwMDAwICAwQDAwQEBAQEAgMFBQQEBQQEBAT/2wBDAQEBAQEBAQIBAQIEAwIDBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAT/wAARCAGgAfUDASIAAhEBAxEB/8QAHgABAAEEAwEBAAAAAAAAAAAAAAkFBgcIAgMEAQr/xABGEAABAgMFAgkICQQCAwEBAQABAAIDBBEFBgchMRJBExQiIzJCUWFxJDNScoGRkrEWFzRTVKHB4fBDYoKiCNEVRHPxY5P/xAAcAQEAAQUBAQAAAAAAAAAAAAAABgECBAUHCAP/xAAlEQEAAgICAgICAwEBAAAAAAAAAQIDBAURBhIhMQdBIlGhE/D/2gAMAwEAAhEDEQA/AP3UIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIuJe0b6+CDki6+FZ2/JcTGb/AAoO5F0cOztHvTjDO0e9B3oujjDO0e9OMM7R70Hei6OMM7R7194dh0ofag7kXWIrf4V9ERp3oOaL4CDoV9QEREBERAREQEREBERAREQEREBERARcdpo3/quPCN/lEHYi6jGaP/1ceHZ2j3oO9F0cYZ2j3pxhnaPeg70XRxhnaPenGGdo96DvRdPDtOmftX0RWnu9qDtRcBEadFyDgdD+iD6iIgIiICIiAiIgIiICIiAiIgIiICIiAiIg+EgarofHa0HOnzXXHjBoO7sz0Vsz9ptgh1XDTtQVqLPMZWrgFSo1sQ2HpjLvzKxva96IcAOPCAGtczRYwta/8KAXc8BQabSDYSLeGC014QdmZXjfeeCCTwooOxy1DtDFKDDLqzIGeu3RWvHxbggkcZb2dNBu6b0wKnnW+12a+fSmB9634h/0tE3Yvwc6TbQNw26FdRxegbpkV9dBvh9Kpf70e/8AZPpVL/ej3/stDfreg/ih8afW9B/FD40G+X0ql/vR8X7LtZeiCdIoz/uWhIxeg1zmh8a90vi5BJA403L+/sQb5w7xwnU5wduuaqkG2YbyOWCfHJaQWfijBilvlINf7qrJFkX9hRywCMKmme0g2tgz7X0zB8VUoccO0Nc95qsKWPeRkcNpEBqO1ZGkJ9sVrTtVr3oLtBBFQvq80GIHAVP5r0oCIiAiIgIiICIiAiIgIi+E0Ff4UHFzw3+ZBeOLMhoNT7yuqZjhgOffWqs61LWbBBq8ZV30QXFHtNjK1cMtRWipMa3oTKjhBTxzWJbZvdDl9vnRlXrLFlrYiwoJdz4FB6SDZyJeWE3+oB/lReZ16YAJ51vxLTCcxXgsc4cZA/zVBi4uwams03495Qb1/SqX+9Hv/ZPpVL/ej3/stDfreg/ih8afW9B/FD40G+X0ql/vR7/2X36UwPvW/GFoZ9b0H8UPjXMYvwK5TQH+dP1Qb5tvTB0EUZnc7Jehl5YJy4RpNd7loZDxegkis000Na7aq8rizBcR5S3X0+9BvZCt6E4ACIO7NVSBasN9KPHvqFplZmJkGKRSYaa/3LJNkX3hRtikYEkDrINmIU211CD+eq9rYjXf97liqyrfZGDeXWvfqr4k50RACHV9qC4UXVCftD5LtQEREBERAREQEREBERAREQEREBdcRwa0+9di8U2+jTnTd3oKDac2IbXcqmXgsN3nvEJdrzwgbQHKqvK8toCFDiHa0rkCtRcRL1cWZH5ylAd9EFGvpiCyV4bnwKE9ZanXwxhbLujDjQFCcttY2xTxJMvxjn9K9bJR34iYvPZEmAJk6mnKQboW7jmGOiDjmdT11jmbx5G0fLK7soijFvDjDFdEeONGpccg/NY/i4qzERx8pdQn0tUEsrseHE1E373rrdjs+hJm/GkRRRQ8SJp4HPuJ9clexuIE0RXh3j2koJTfr3P4s/GE+vc/iz8YUWf0/mvv3+8hcfp9N/fv+NyCVBmO5r9rPfzgVdkMcnOcPLM6+nUqJZl/5ra8+/TvyVz2Xf2aLmDhXjP00Ey93MZXRnw/KgSaddbNXMxLdMOheUV2qHpKEm5t9plz4VYrjUjet38NL0x4hgViE6VzQTH3MvaZkQucqCBTlVotmbuWnwzYZ2tRuOijowztiJFbLkuNCAdVvDcyZc+HCzOgQbFyMTbaM61GarAzAPaFbNlvqxproNFcrOiEHJERAREQEREBERAREQF1RTRvZvqu1eaYNG91KILXtWZ4NjiTTJYQvVbnAMiHbpSp1WVrwRS1j89B25rVu/086HDjkE5A9yDEN9r8mW4XnqUrSjswtTL3Yrul3RfKO05vVTxQt6LCEwQ8ggE6qPjES90xCfH512pyBQZytvGt0N7hxumZry6qwpnHRzXEccP/APotDrz35mmxIlIrtT1s1iicv9NbZ55+pHS/JBJz9e5/Fn4wn17n8WfjCiyN/wCb+/f7yF8F/wCbr59/xEoJTxjuSRSbIP8A9F2/Xs8f+2PbEqorfp/Nffv/ADXU/EOabXnn++iCV6HjzQis2af/AEVx2djwC5oM4PDhM1DlExMmYZqZhw/yXrksW5iFEbWZcM/SKCeC7ONzYr4Y432ddbOXMxVZMGEOMA1p169i/PTdHGOLwkIGaOo/qZlbuYZ4sPjPlwZnUjrUQT3XPvq2ZbDpGBJA6y2NsC2Wx2Q+XWu+tCVFFhbf8zIl+frUAdJb9XGt/jMODy61AyrVBtfJR9trTWte1VUGoqN6suxprhIbM6mmdCrxhmrUHYiIgIiICIiAiIgIiICIiAiIgKjWg8NhnPOmfeqw7Q+Cty1nUhPAOdM8kGEL8T5hQY1HDIHeo8cYbyOgw5qkSlA41qt4cRZssgx8zUAnRRcY5Wq6Gycq46Oz0QR7Y033iQ3TQEY1BdnVRi4jX4jPjR6RnVLjvW1uN9tOMWcAeek6majavpOxY8zGq4nlHfVBQ5+80xMRjSI41cdDkvfZkeamXN5TjXtqrVsyy4s3MCjSakbqrY65Vw402YR4ImtD0UFDsyzJuMGkNfn3Eq8IFgTjgOQ/PPQrZq62EsWNDhkyzjWnUrRZhkMFYr2NIlTmPQ7kGh/0bnD/AE4nuT6NTv3cT3KQkYJRqDyR2n3a+/UlG/CO+BBHuy7c4D5uJmKaK6LJu9OcI3kP1Gq3ibglGqKyjh/gq9ZuCkZjx5IdR1EGAbl2DNNiQQYbjmM6Fb1YYWRMNdL8lwGQGXaui62EMSG+HWWOoz2PBbaXCw4fLmDzBFKVGygzlhfIxWNl6g5NB0W9lyoLmsg17lr1cO6rpdsCsMigG5bY3XswwmQxQ5UrkgytZTebaN5Vzs6IVEs+GGtb4dmirjRQDwQfUREBERAREQEREBERAXmmRVvsr816V0xhVp8DmgxveGGSx5Fd9MslqniDLPfDj5EmhpTPtW4Nsy/CMcKajQBa/wB8LFMdsXkk1Brkgi1xTs6M8TFGnfuUdWI9izDnx6McTU7ipl7/ANynzHDUhVrUZNqtK774XRI7ox4AnM57KCHa9N35sxIhDHipOVCsSTl3ZwvPIfkdQKqUy38G4sR8SkqddCxY3msEoxc7yU5n0KoI6Po1O/dxPcn0anfu4nuUhX1JRvwjvgT6ko34R3wII83XcnADzcTTLJUmcsObY0nZeN+hKkdi4JRtmplHDI6sVoWzg1Fhw3HipBppsII1LWlZqAHGjhTtWPZu05mWeeU/L3Dct6r5YXRpdkXycigPUotSr4XSiyb4g4MggnqoKfdy98eDGhgxXCjt7s1uzhTfuLwssDGPSFOV4KOGDBiysyNcnZLZTDK1IkOYlxtkUI3+CCenBS+L43FKxSRyaUKlYwrtsxoUtV9agb81BJgRbLyZMbZ1bvUxuDdoGJBlDtHMNpvQSS3YmuEhQ6nUDJZOlnVaOymSwrc2MXwYNOwLMsoQWtp2f9oPciIgIiICIiAiIgIiICIiAiIg+O0PgrWtnzcRXS7Q+CtW2/MxfAoNUcTYtIExUmtDu1UUOPEwRDnM/S7VKtieSIMz6riomcd3nYmySacrJBDtjRGLo82Kk8p2QFAtELblTHm3Agmrs+7Nb04w5zEz2ku+a07m5YPnTUZbR0yGqCpXHuwJmZhAw61cN2SkPwmw5ZM8XrB2q0z2arV7C+yGxJmXGwDyhuqCpYcELsw4glKwx1TpkgyhcHCGHFhQCZYaDPYWyVk4LQ3Q2+SDSvQ0WbcNbnQXwZccCOiOqtsrEuPB4FvMtzGXJQaDNwShbI8k3fdhffqShfhP9ApJW3Fg7I8nZ8K5fQSD+HZ8KCNkYJQgQeKe9gVQlsF4bSPJB3c2pFvoLBGfAMFN+yu2HciAADwLda9FBo3ZGEcOE5vkoFCOosvWBh0yXczmANkjq0WykK6kCEfNNyPo6KsS9iQIWew0ezRBYlgXYbLhlIQFKdWqy3ZdniCByaUpRfJaWhQqUAGWW5VyBEhtpQhBVpeFQAaZZ0XtVPhTDcqGnZTNetsZp7D4IO1F8BB0929fUBERAREQEREBERAXFwqPzCF7Rvqul0do308Mygpk5Lh7TvFFj+2bHbGD+QCDlosjRY7DlUadqpExwbxuoT2oNaLw3MZMiIDBBJJ6qwjbmGDI5f5PWta8hbzzNnQYtagEV3hUKYu7BijzbaHPNv8AO1BHHaODsKI9x4qNfQVsxsFITifJBn//ADFVJbEubBiE0hNPfsryPuPBLqcC01GmygjW+pKF+E/0CfUlC/Cf6BST/QSD+HZ8KfQSD+HZ8KCNGPgnCDfsg09AVWObyYMQ2QonkoGVegpa5i40ENPMNAp6PisV3suRAZBiEQh0T1UEEWJeFDIMOY8mAoCehoo1sVbitl4kyBBoBU02aUX6FMXbowWQZnmm9E7gojsbbvMhvm6Qxv3BBETblh8Xmn0ZSjzu71e9xGGFNQQBSjwqzfKzmw5uLyR0yO9dF0IOzNwqDrDcgk2wImHB8nuzbuqFM7gpHJhSlSTyW66qFXAwlsWTOWZbr7FM5gi48HKN/tagkuuO6sCDnTkjKqznI9AfzcsEXFNYME9rQfyKzvI9AfzcgqCIiAiIgIiICIiAiIgIiICIiD47Q+CtW2/MxfAq6naHwVq235mL4FBqRif5mZ9VyiXx481Of5KWjE/zMz6rlEvjx5qc/wAkEO2L/wBomfE/qtS4rW8d065+a20xf+0TPif1WpsX7b/mfmg2awngtdMS5NOmNfYpgcB5VpEnkDmFEJhL9ol/XCmGwF0k/EIJXcLpNpgwOSBQDRbf2JIs4GFluHYtT8LPMwPALcCxPMwvAILhZIs2Rl8ly4izs+S9zOiFyQU50kwDMD2rxRJeGwHLRVqKaNVt2hNCG12enaNUFPmY0OEHHJW3N2zBhF3LFR2mit+37eEAO5YAHYVgi8d+2y5iVjBoBOpzQZ9iXqgsJ5wHPtXyFe2EXZRAPatJbRxQZDe7yhoofSzXnk8Uob4gAmRmcjtIJAJO8cOJTnASe/VXVKWk2KBR1ajIrSm71/mTDmDhq/5arPN3rxCOGc5Xd2oM+QIwfSh8KL3g1AParPs2cEUNNdVdcFwcNaoO5ERAREQEREBdcR2z3ZVJGq7NFTpqLshxr3oOiYmgwHPvpVW3N2w2GDywKd9CqdbFqCC1/KprpmsL3ivY2XD6xKU79UGVJm80JhNYgHtVLN64RJHCjXLPJao2ziOyC9wMelP7laH1pQ+ErxgUrTpIN6pe8MKKQNsGuWtVcMrPwouzmDktI7GxHZGewCPWv9yzdd29jZkM5zarur3oNjYAhxAMgqhDlIZzpu7NFZdj2oIzWcqqvmWibbRnuQc+Is7PknEWdnyVQ1RBRJuRZsHLd3d6xNe+RZwETLqns7Fmmb6B8P8AtYmvf5iJ6p+SCOzGOUaIU1Ro0OvtUOOO0s0OnKgau3eKmcxj81NeDvmVDZjx0pz1nIIsL9wmtm4w/vOQyCoN1WgTcKnpBXFf37ZG9dW9db7XC9YfqgkcwP8AOyfrBTNYJdCT9VvyUMuB/nZP1gpmsEuhJ+q35IJKrieYgeq35FZ4kegP5uWB7ieYgeq35FZ4kegP5uQVBERAREQEREBERAREQEREBERB8dofBWrbfmYvgVdTtD4K1razhREGo+J/mZn1XKJjHcEw5wD+5S24mwyYMxTsJyFVFFjtLksnKCuTtcyghmxfB4xMj+4ju3rUyL9t/wAz81uPi7KuMzM5HpH5lamRZR3HdHdM7u9BsZhL9ol/XCmGwF0k/EKIrCaWcJmWyPSH6KX/AAJgENlMqaaDwQSxYWeZgeAW4FieZheAWoeF8Mtgy+R6IW3tiA8DD7hUoLwZ0QuS4s6IXJB5Zl1Guy0FFjq8M5wUN5JpQGudVf8AOmjHUNO3Oiw3e+aMKFFNSMjqgwHfu8nF2RiH0pXOq0YxDxGMq6Pz+hOrlnXFe3HQIczR5FAc9rJRXYxX2fLvmRwpGbqculNUFzXgxf4KNEHGhWp69AF4rGxh4SO0cZqdrdEqo3L34lPZMxQI7ukeuqXdvEyI+aYDHObvTzQTtYf4kGZfA5+tSBQuqt57g3o40yCeErWm9QWYQX6fHiSw4Y6g02qqVTCS8BmIcrV9agZ1qgkvu3P8LDhmuoGdVlGUeS1v/wCrANypsxIMEl24VIOqzrIOrDBruyz0QVhERAREQEREHF3RKt21I2xDcdMqq4Yho0qy7dibEOJnSgKDD177W4CHFIdTI7960zxCvrxXhudIoD1qLYLEW0zChR+UdDvoo1MYb1PlxNc4cq76ILTvlirxeJGBmcqkU21iP64ue+1db0v3WpeJOIcSDMR6R6ZnrLXj6z4nGtnh+tptoJmLm4qGZiQgJmuY6+a3Ww8vrxoQeerkOtUqBjDbEOLGjwPKCakddSfYOXqdMCWrEJrSnKzQS6XQtbh4cPlk1A3rOVmRi5jTWoAHitRMOrSMaFA5WoC2qsOJtw2VNTlRBejeiFyXCGat9uS5oPJN9A+H/axNe/zET1T8lluZALSDpT/tYlvcCYEWg6p+SCPnGPzU14O+ZUNmPHSnPWcpmsY4RMGa8DmPaoc8dZdxdN5Hfmcu1BFNfwHjkbI9Mq3rrA8bhZdYfqr1v3KOM3GyPSKt660m4TkPk6OHzQSE4Hg8LJ5HpN3KZnBIHYlDTLZbn7FDxgdKkRZTLRze5TJYKQSIUp6rdB4IJH7ieYgeqPkVniR6A/m5YLuO2kGD6oKzpI9AfzcgqCIiAiIgIiICIiAiIgIiICIiD47Q+Ctq12VhPOtRpRXNqqJaLNqG7vbpRBqpiNKl8GOKbiNKKL7G2yXRGzfJz5Q0pWqluvxIGLCigNGYKj5xau0Y7Znm665UrVBBZivd2I+YmebOp3Z71qvEuxE45Xg3dM7u9SoYk3DfGjRzwJNXGnJotcImHMTjNeLk8r0UFmYXXeeyZl+RntDQeClkwQsp0MSnJyoKA+xag4eXCfBjwDwBGYOTVJJhJdp0AS3N0AA3IN6MNZcsgS+VOSN1StrrEbSEwV1FFr5cKQ4KFBGzSgGoWxtlQ9mGyuoFR3ILgb0QuS+DQeC+oKXPmjHjt/dYHvzFLYMbM9E6nJZ2tDon2rAN/vMR/VPyQRz40zz4cKbIcei7eoaMdrciQ3znLOrs6qXrHB5EGc8HaqE3H6M4Pnd2btEEe997zRWzkYCI7pHf3qjXVvNFM5D5w9IU5Wmisu/U04TkWhObzXvzVFulMuM5BNTm8D5IJbcDbeiRIsoC81q3fopmsELQdEhydTlQDsUFOA0dxiSmp5Td9OxTbYEPJhSefVB+SCVjD+MXQYG8bIK2Osw1htHdX8qLWTDokwJcnsC2YsrzTPVQXAiIgIiICIiDri9A/wA3FWBeN5EGJmdNd6v+L0D/ADcVju83mH+qfkUGm2Kc0WQZnMigO9RJY8Ws6EJzlUydoVKxiwSIMz4H9VD1/wAgIrmtnMyBR2ntQRWYs3iiMmJkcIdXb1q79J4vHfOu8529yyzi9MuE1MivWO7XMrVXjb+OdI+c7EG+uE94oj5mX5w9IeKmAwItZ8USlXHPZ1OSg2wgmXGZl6uPTGVFM5/x/iuLZHM57OZQTM4VzJfBljXcDqtzruv2oMOnYDVaQYSkmDLV9Efot27teZh+qEGQoXQH83Bdi64XQH83BdiDzzA5JPd/PmsXXrhh0KLStaLKkYVbQ6UKx9eKDtwn0roadyCP/FyTMSFM0bqDQ08VEhjbYz4jpukOoq7Kme9TXYl2QY0OYAZtZE1oo0cWroOjumOarWvVQQpX2u1EdNRqQz0idM1RLsXYiCch82cnDct0r2YePfMRSIFauyyz1Kpl3sOojJljjLkUcM6d6DJWC1gPZFleQdW7qKXTByzXQ4UtUHIN1GS0ewouW+C+XJhUFR1VJlhfYfAQ5fkEUA3INuLmQdmDCqNAN36rNMm3Za3wWM7ry3BwodBTIeIWUJZtGga5VBQepERAREQEREBERAREQEREBERAXgm2bTXZePaveuqK3aafChQYkvLZ/DQ4lW1qDuWp9/bqcabH5o5g7qreO05IRGOyrXuyWJrfu62YD+bB1OiCKi+WG3DxYx4CuZ6lFhyJhTz5PFh0tdmoUp9t3FbGc88CDUknLJWS/DiGX14uNfQQaZXSw14CLDPAUoRoxbjXAulxYQebpSmrVd1j3BZBc08CAAd7dVma712mwAzmwNNBqgue61mcDDh8mmncsvSMPZY0d1PCqtyypAQWtFNArwgM2WjuCD0IiIKVaAOy47hr71gG/orAjj+0/JbAzoqx/fULBN+YVYMb1T3FBGDjhDJgzlK6ONaVUJeP0El87kTm79VOjjVIufCm8q5Gu9Qv482Q9z5yjDq7d4oId7+S7uORqA9M/NUS6UBwnINQcnA6LLF+rvxDNxjsV5Zrl3qhXUsCI2bhHgzk4Uy70G+uA0Jwiym6pbr7FNxgQ0iFJ5Hogaa6KHXAyyIjIsodilS3dkpo8DZJzIUmCNzdyCTLDoUgS4PYFszZXmmeqtcsPYOzAgZUGyFshZgAhNPdT8qoK6iIgIiICIiDri9A/wA3FY7vMKwH+qfkVkSL0D/NxVgXjYTBiZHTTeg0cxYB4GZyOh/VQ8f8gIbi2cy9Lv7VMxirLl0GZ10O5REY9Wc54nKNrk6hAzQQgYvQXcamdekTp3lap8EeO7/Oej3LeHFuxXumZnkE5kjLvWq//govHej/AFOzuQZ2wfgu4zLZO6YKme/4/QyGyXds5aqJbCOxIjJmWOwekK5aqYzAWznsbJ1b6OgoglmwkBEGVqCOSNy3bu15mH6oWmmFMuWQJbLQBboXdZSDD7SBlVBfsLoD+bguxdcLoD+bguxBxeKtPdmrVtaX24bwRu7MgrsOYI7VS5yDtNIpuQay30sTh2RRsVBB3LTC/txuMujUg1rUdHTVSTW3ZIjtfyAVhO8F0Gxy+sIHaruqgigt3C7hYzzxff6Oa8tkYWBkZh4v1t7VIpP4eMe8kQBWuuyuuSw7Yx7SYFM/RQYIuJcHi7oREChBHUW59yLviXZCBh0pTUa6LosC5rYBZzIGedRms2WHY7YAYNgaaAILosWV4OGwEaDsyV5Qm7LRlTcqZJS/BhuWY7qFVcCgA7EH1ERAREQEREBERAREQEREBERATVEQeKPBDqg6+FaqgTdmtiVq0EnuV1kA5FdboQd2HuKDGc1d+G8+bFDXdWqpZuxDP9Me4LLLpYHd7V1cTZ6J+FBjeWu6xjgeDGvYrlk7KbCpRtP1VziVApl+hXc2ABTID8yg8kCAGAZfuqiBQUQNA0951X1AREQeGcbtNd3LD975bbgxstxyAoFmaYbtNOVajRY9vDKCJDiZbj3oI5cXLFMWFM8jXaUTONNznx3TdIRNS7OlaKdLEK7omGRxsVJB3ZnVR84m4e8ZdMcxWtTUNQQJ3zw9iPmovMHpHq5KiXaw8iMm2HgD0gc29hUmV58Ji+PEPFieUepVUexcJDDjsJlut6FCgt7By5kSDElSYRFHN3KWvB6wnQYUrVhGQ3ZrWrDfDviz4FYFKEdVSE4cXcEsyAODpQDKmaDZ648oYcGDkRkMqLPMg0iG0ZZiixddeUEKHDFMwAsrygo0DKtQgqCIiAiIgIiIOEQVb81ZlvQtqG+o1B3q9H9Eq2rVYHse3uyQafYk2eYsGYAbUFpGai7xqu0+OJo7BNa05Piphr62aI0KLlqDVaJ4m3PE0JikIGtTkK6oIDsULiPix5jmTm49Va3fV5F43XgD5zWimGv1hgY8aM4S4qXHq1WFhhIeMVMt1vQQa7YX3GiQ5iX5kjlDPZpTRSs4K3ZdBbKVhkUDdyw7cTC90CLBPFyKEdRb/YZXNMs2X5qlABpkg2mw2s4woMAbHVBrp2LbGwoWzCZkBQdlFhO5dk8DDg8k5AaBZ9suDsMYKbvYUFwMFG+3Jc18boPBfUBdUVgcD+a7UQUKZlA8Oy1VszdisiEnYrksgOhg/wAyXQ6XB3D2IMURLtQ3OPNj3JDu1DafNjtGVVlJ0o06jwoEbKNGg8ahBZcpYjIZB2AMuzNXLLSQYBRoGW4KqtlwBoPaV3BjR3/kEHCEwNHhou5EQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREHF4q0+9W5aUtwjHgite3JXKvJHhBwOQ0QYEvNYQjtiUZUEEVWtF7rjMmDEPAgg16vit6bRs5sQO5P5LGds2BDeHVYCPDVBG7bWGMJ8Rx4uMzqGqgy2G8KDFB4BooankreW2LuwW7Z2G5dyxtaEhAlnO5IGdNKIMdXZurBlHQ6wgKUy2VsfdaBBlxD0FKLDP/AJSXlHDlNFO+irkjfKXgFo4Vop357kG4FizsNjWjaGQ3q/pSeY4NAcDXRai2PfyCdgcMMz2rKVkXvhRQ2kUfFkg2DhzAcBQ5L1Ag6LHlnW5DihtHg7zmFdktOseBRwzQVhF0tjtcBmPFcuFZ2/mEHYut8QNr2rpiTLWjUDL2qiTdoshg8oadqCpxpprQake0q25+eZsuzH/Sti1bxw4IdzgGu9Y0te+kGEHjhh3guQV+8MaFFa8VByy3rXi9VlQZoxOSDtVGlVWbUv1Ac5w4Ydg5WSsebvRLzLiOFBqe1Bhm3rkQZl7zwQNTrsq0oWGUJ0QOEuCSa9HvWxUKLLzThm01NK6/zVXdZdjQIxYQxpqanJBhO7WHDIT4Z4AAZaNoQtmbo3SbLiHzQAAFDs0Vy2LdyCNmkMZa5LLFkWMyGG8gCncg9Vg2WILGcndTILIspC2WgexU+SlAwN5NFXobQ0DvQc0REBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBfCAdV9RBT5mEKHTVWTa0JrWuJ71fczofEKwLfibLH57iNaFBha88wyCyITTKp1Wr98rzQ5XhecAIJ3rM9/rSMGHHO1QgFR94qXrfLiYpF0rXlIOd5MSmSr4g4cCh9JY4iYyw4UWnGhr6a0uxFxNiS0SOOMEUJ61Fqza2ND4MZwM0cnenRBNLYWNMNz2DjY1121sPdPFuFGMMGaB8X1X55bAx2c2KwGcpQjLhFtJcTHdrjBrODcfOIP0GXZxEgx2w+fBrQdJZqsm+EGIG88O/lKFi5GN0N4hVnAdKViLaK7mMcF8OH5UO3poJNpe80FzRzjdO1et14oAFREGvatFZHFuC5jazQ09NVSJizADR5U2tKnloNvpy9UFjTzoyb2rHNuX4gwWv54V9Zas2ti7Aa1xE0NPTWC72Y0QobYtJsZA6vQbOXqxOgwOF8oGVevota70YxQoZi+VAZnr0Wn1/McmMEbywamvLotN7548gPigToGZ/qIJILSxrhGI4cbGvp1XGz8XYcxFb5UDU7nqG2bx0fEjkCc350fmr3urjA+Yjw/KSakU5aCci6t/YU26HzwNSOsFtDdC2YcyIfKB2qHWqhwwxxDfMvgc+TUjrVUjWGV43zDZesStQK51QSB3ecyI1mmnbmVlaz4LdkLBFzJ0xIcLPKg1NFnmy3bUNvsQXHChgD8l3rgzQ+K5oCIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIg8kyMj4grHN42ksiUG471kuMKt9ise3Zfbhvy3b0Gl2JYiNhTFNKFRfY0zEaGJuhI1zrRS04jWUYkKPRteSc9VGHjZYER7JqjCRmageKCGHGG2o8CJNHbcANrf4qPe+N948tHi884UcT0lIljpYEaG6cOwdXbvFRPYoyseWjTBo4UcSg98litGl448pcKH081nm5mNz4ToVZt2o66jAte248nHeOEcKOpqudk4hxpSI3nyKHTa0QfoBuNj6WCCDO0rSnOLa26/8AyCaGw6zo0GsTML84d2MY4sAwwZo0H9+az/d/HWIwMHHDpvfTcg/RHZv/ACDZsNrOiv8A9M1WYv8AyCh7H23dnzn7qBez8fntaBx0ju4RVWJ/yBiFv206feIJm7b/AOQTSx9J0Co+8Wvl7/8AkCCIo47uI85qoubWx8iOa/ywnv4SqwreTG+LG2xxsmv99O1BvhfrHh0QRqTlaV/qVC1KvTjREjxIg42cz94tP7y4sRpgvHGiamvT1WJpq+8ebinnnGpr0kG7ctibGmZgeUkku9Kq2Nw5vfMTEeAeFccxXlKM26loTE3MQ+UTU7zULfrB6z48eLKnZcc27kEu2CtrR4zpUlzjVwGqlwwdjxXw5XU1Arn4KJ/AewYp4mdg9VTD4OWM9kKVqzc06IN8rhhxhQa9gWxtkAiE2vYFg65MgYcGDydwyos92bC2WNy3aUyKCvs08Sua4t6IXJAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREHFwqD7wqDaMsHscKVqPergXlmIQc094Qa73ysUR4UbkVyO6q0Excubw0KaPBVyOVFKTbtmiNDfyK1BzpQrVrEO6zY8GYPBg1BBy1Qfnhx3w/c5s4RBOjtyhpxruO+DEmyIJFC412aVX6fsbMP2xWTZ4DUOpyct6hnx4w3LTOES/aOj4oPz04g2LFlI0ajSCHGuS1ytKejykVx2nDZKkgxhuO6BFmjwJGZI5Kj4vrY0SWjRgGkAE7kFBlL4xpd3nXCh7VelnYkR4VKzBoMs3LXS0HxID3UJFCclSBa8WGemcjvKDdCWxTjtaPKXfGvY7FeMR9ocO2r1pWy8MVv8AUI9q7XXhj0ziGh70G2k5ihGe1w4w7MU6Ssi0cQY8XarHcajLlVWvL7eivqNs59pXSLSiRTTaJrnrkgzBFvPGmnEGISSe3VXNYLo03GZqakd6w9Y7IkxEbSp7qrZnD670SaiwKsrUjdVBsPhhd2JMxpc7BO0W0yUruBlxHxHyZ4Emuzns6rUzBS4ZjRJQmCTUt1bUKZrAXDrKSJgej1UG3GBlxHMZJngiKBueypXsLrq8DCl+b6ozpRa54OXHbBhy3M0yHVyUiFx7vtl4UHkUoBlRBku7VmCFDhjZpQBZRlIWy0Cm6iotlyYhsbyaeyiuaG3ZaEHYiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiL4XAa+7eg+ouoxWj9c1x4dnaPeg70XUIzT2e9cw9p7vFByREQEREBERAXwioI7V9RBR52XD2uBCxDeuxWxoUWjK8k7lnGKwOacvFWla8kIrHDZ1HYgjexUuY2YgzPMg1BpyaqJfHTDkPbOEQK9I9HxU/1+7uNjwo3IrUHd3KOjGS4TY8KaPAag6NQfl4x0w5LHTh4DtPRp2qJ7FK5rpeNMc0cnE9HxX6XceMNvth4v6Q6PcVDZjRh86FEmjwFM3ZbFO1Umeo7PtDDeiyHQIsWrCMzuyWKJyE9jjkdcqCi3LxAupEgRY/NEAOIpSgWsNt2S6HFeNmgrnUaKnvVd62/pj0xHAmnb704V/b+ZXtjyjmuPJO/PRefi57/AOexU/6Uk9LOtr3F36jVV2zoDoj25VzGa8UvJuc4DZIzWRLvWM+LEh8kkEgZiqResnrb+l73PsR0xFhcgHMbtVvxhHcp8eNKnga1IrlksEYa3RdHjQKQzmRu1UpOB+HpiPlOYrQt6texVi0SpMTH22rwHw7L3SZMDXZ3aaKaHA/D8QmSZ4GlA3q+C1TwIw52BJngKZNHR/napfMIrlNgQpbmdACTRXKM+4a3UbAhS54LQDqrbu71mCDDhjZpkNdSrBudYYgQoXI0AGizhZ8sIbG5Uy9yCpy0ENaBQexe1cWt2QB71yQEREBERAREQEXwkDU0XAxGj9K5VQdiLpMdg1p70Edp0ofag7kXARGn9d9FzBB0QEREBERAREQEREBERAREQEREBERARFwe7ZBQdcSLs7/3VMjzrWVzA7l0z00IYNTRY7ti3WwQ7l0p35hBeMa12MJBeKDPXReL/wA8za842nZXNYKtS+cOC5wMXMH0lajr+w9sjhxrTpINqIVssca7Q96q8Cfa+lHVrrmtXrOvtDiuFIw112lk6x7wNj7PLrWmhQZphRg6mev5r1g1zCtSz50RQ3OvfVXNCftAeFUHaiIgIiICIiAqfNQQ4Hfl7VUFxe3aFNUGJ7x2U2NDeNgGoO5agYmXRbHhTHNDMOyot9rRlBEY4EVBHZmsH3xsBsxDi8gmoIzCCC7G7DlsZk4RArUO6me9Q3Y5YYHanKS5rV3UX6c8VbiiYZMcyDUHqV7VFVjThaYomzxYEnaPQWDsZ4x19pZOHH7zEQ/MBiphxEhRZnmCBU5bFVo/eu5L4UWLSC7U7lP7i5hI4xJoiVNOUehnvUfd98KHtixiJU5E6soojyHkOPV7m1kg1OIvm6mIRTz11ojXnmSM6DKtVShdmJXOEaV12VvRauGURsR3k7tTo3JW83DWJtDyd1a58lRm/nOvS/rN4bqni+a0fFf/AHw1Us66sR72jgjmdaaLOVzrjPixYI4EkVA6KzLY2GMR0Rnk5dnnVlAtl7g4TvdFg1lTqD0dVtNLy3DsTEVswtnx/JijuYcMI8OIj4sseLk5jPYopdcCsNCHShMvSuz1FifB/CYtiStZbI7NORopacF8MRBEo7i9NNWKY6W/XPWJ7R3Z1bYZ6mGwWCmH7YTJQ8ABQDq0UmmHl12wIMA8GBQAaLCuFtzBLw5ccDSgBPJW7d1LGbBhQwWAENG7Rbqk9x01to6npethWcIMNmQGQ3ZBXxAhhoGWnvXgkZcMa0AKrgUAHYr1r6iIgIiICIiAuL3Bo1zXJeCZi7LSa/og640yGVzVHmLTYyvKHfmqPalpiE11TpuqsW2xelsAu5ymoPK1QZXfbjGkjbApvJXxluwzkYgNTqCtaJu/cNjiBGGR9JcZW/bHuAEYa58pBtbAtRr6codgVZgzIfShBPcteLHvWyOW0i1qaHPVZTsq1Wxmt5W7t0QZDY7aH8zXNU6VjbYBBrVVHVAREQEREBERAREQEREBERAREQF45l+y06aUXsVHn4myw5mtM+9BZFvz/BMea6VWtl9L1CWEUcJSlaVNFlq+VocFBjcoCjSdVojijeky4mCYlKA5goKNerEdsB8UcOBQ+msVRMVBw1OMjXc/Nau4hYhugxo1I5GZ61Fr7FxOfxmnD57W93eglkuziQI8SEOMA1I69VtPcu9gmeC52oIG9QuXCxDfGjQax+sBk6qkJwtvU6YEtWLUkDegk4u5aQjMYdqtRXIrJ8pE2mt9+q1xuPaXDQoPKrkM1sBZkTbhtNa5dqCvIvgzAPaF9QEREBERAREQeaYhBwOVaqyLbs4RYbuTXLcFf5FRQ71S5uXDwagH2Kk/Q1CvxdVszDjc0DUEaLQvFPDdsy2ZpArtA05GRUtNvWM2M11Wg1FMxVa3X1uayYbFrBrUHqqO8zeaYZ6bjjqxfLESgAxUwgbEdMniuQrXkLQC/uDVYkY8Vpr/AEyQv0W4gYZsjCN5PUEnPY8VpPfjCZjnxjxaoqTTYXmTzvnc2nFprLtXi/GY9maxMID7bwcLYj6yhpU6sIVpDB88IKyvW3w6BTA2/hG3hHkSwJqT0VZzMIm8IPJs6+jkF5m3/wAgbOPamvv/AK7Tp+KYL4ItNUdl3sHC6JD8lyqP6dVtVh/gxSJBJlMqgmsPNbW3bwhZtw/JRWudWLam4mEzGOg+TAUpXkLpvhHl+xuZaxNkK8l4DDr1n4YzwqwjbCMv5LSmyRyNVJNhhh42XZA5jQNpyUw/w2ZA4vzAFAOrqtyrm3QZLNh82AAKjLNeufFdm+fDWbS4BzuGuO9ohX7lXabLw4XN0yHV0WwVkyIhMaNnQbhRUKw7KEFjKM0yPuV/ysANAy9+5dLxfUShmT7eqEzZHyXcmiL7PmIiICIiAiIg4uNGn3K3bTmNhjjWmW45qvxTRvvVi2/H4OFE5WgO9Biu9dtCAyJywNTrSi1RvpfcSxjc8AQT1llLEW2TBhzFHEEA71HZilfR0u6PSMQAXZbSC9bYxQEOK4cYpQkdKi6LKxSD4rRxgdKvTUeN6MSXw5iIOHpR29/7qn2BiY90wwcYrytzkEz1zb+iZMLnq1IyL1thdK3xMMh8utQN9aKHrDC/To75ccNWpFeVqpGMNbeMwyX5dQab0G8tkzPCMYSc6Vz3K6YZq0LGd25rhIcM11HbVZHl3VaKaUQehERAREQEREBERAREQEREBERB8Oh8Fb1rPpCfTWlMjmrhdofBWtbJIhxKGiDW/EOcMODHz6p31UZeNFtuhNmqRCMnZ1qpF8TIpbAmOVnsnuUU2Ok2QycNdzswalBHNipeyJDjzAERw5R35LV6JfKIZwjhT0/S71fWLloubMTIDqco5171qfEtN/Hen1zoe9Bv9hjeuI+YlxwpoXDKualUwWtp0VsryychQ1zUJGFFoPdMy3KJqQpecCpouEpU9lc/BBL5hxOF8GBUg1AzC2msZwdDYajIblp/hjFJgS+ug1NQtubDdzLP7ggvBug8F9XFnRC5ICIiAiIgIiIC4PbtD+ZrmiC352Ua8Hk+1Y5t2xGxmPqwEU7Fl+LDDgTkqFOyrYjXCgOW8LS8ngnLhmIbLSy+mSJad3sugyIIp4IEGtMlq1e+4MN5i0gimY6KketyyGxGxOQN4JpuWC7yXba/hOb94Xl38j8Dmz0v6x27b4dymPHavcoy7cw7YXvPADIkU2VaDMOmGL5jfpsrfe17oNc9/Nbya7OqtuHc1nCDmhrlyV475XxPctvTMVn7ehdHndeNX7/TXK7uHTA9lYAGdabOS2TufcGHD4M8AK5U5KvOw7pMa5nNU8Rms6Xcu6yHsc12Z039i7R+OfGdnHkpN4n9Oc+X81hyUtES6brXSZBbDPBAUA0as62NYzILG0ZQgarhY1kthhg2dB2K/pWVawAAaCnYvavi+hODBXuP083c1txly26lyk5VrAKCngFWGt2QAuMNgaBl4Bdi6BjjqqKWnuRERXrRERAREQEREHRHPIPaBVYyvTFLYMTTQ781kuYybn2f9rE97nkQIp1q076UyQaU4sWgYcGZIdTI93aon8abwvhOmqPI1yqpOcYo5EGaz3HUqHrHSdc103Q16W/xQaV30vfEZNRaxTWp3+Kot2b4xDNw+dJo4Vz71iu/VpPE1G5R6RPYqBda04nHIXL0cBrnqglywbvK+LElaxHdJuqlmwgtUxIcryichvqFB9ghPudFleUTm3dqpjsFZkuhSmfVb1kEmFz45fBhZ1yG/RZilDVraaUWC7kPLoEGhPRHcs4yPQH83IKgiIgIiICIiAiIgIiICIiAiIg+O0PgrVtvzMXwKup2h8Fatt+Zi+BQak4nkiDM+q4qJrHZ5EOcqcuV3KWTE/zMz6rlEvjx5qc/yQQ9YvPPGZk1y2ia07ytS4r3cd7eWd3etsMX/tEz4n9VqbF+2/5n5oNosJXu4xLeuFMLgMSRJ1J1Ch4wl+0S/rhTDYC6SfiEEtmFvmYHgFuBYnmYXgFp/hZ5mB4BbgWJ5mF4BBeLOiFyXFnRC5ICIiAiIgIiICIiAvFHh1rl+69q4vFR4fmvjlpF6r6W9bdrNtGUD2kgVyWNrXsgRC6jdSd1KLM8xBDgaioOitydkA8kho37lAPIOCpuVmPXtKuJ5S+taPlrnP3dD3O5vfXSoVHZdobfmx47Kz9MWO0k8mlO6q8TbFbUckewLkO1+P8AFkz+/p/joOv5XemLr2Y2sy74YRVlD3jXwWTbIssQw3k9wAGiqUrZLWOBDc66+5XRJyYYBUZ78lNvHfEcWnNZ9Ub5fn77FZ/k75KWENoFPeKK4ILNkDTJeeBCpTLuC9wAAoF1vS1q4aRWEA2c05LTMvqIi2TEEREBERAREQEREHkm+gfD/tYmvf5iJ6p+SyzN9A+H/axNe/zET1T8kEfWMnmprwd+qhux4cQ6c9ZwUyOMfmprwd8yobMeOlOes5BFtfx7uORvXKt66z3cbhZ9YeCr9/ftkb11b11vtcL1h+qCR/A55EWT73NCmZwSceDlAc+S3PeoY8D/ADsn6wUzWCXQk/Vb8kEldxTWDBPa0H8is7yPQH83LA9xPMQPVb8is8SPQH83IKgiIgIiICIiAiIgIiICIiAiIg+O0PgrVtvzMXwKup2h8Fatt+Zi+BQakYn+ZmfVcol8ePNTn+SloxP8zM+q5RMY7isObHrIIdcX/tEz4n9VqbF+2/5n5rbDGA0mJnsqfmtQpiOGzpz69PzQbV4TOaJiXz64UwmA0RoEn4jU0ULmFdosZMy9XU5QyJ8FLdgZbkOG2Uq8aA5nwQTP4WxmiDArTQb1t/YkwzgYWY0G9R94Z3khNgS/ONBoN/gttrEvTB4GHzrch2hBn9kwzZGY965cYZ2j3rFrL1Qdkc4Fy+lUH7wIMocYZ2j3pw7O0e9Yv+lUH7wLtbeiAT51pPc5Bk0RWnu9q5B7T/2sewrxwnU5weO0qpBtmHEpywSR2oLwBB0IX1UWFPNfSjga5CqqMOOHUzr3FB6UXwGoqN6+oCIiDpiQwRpl8l4YkEHcFVFwLAe6vtCxsmGL/Fvp9aZZqoT5Rp1b7xkusSbK5Nb7Bmq6YI7vknAju95WDbj8Np76ZUbd4/akslWt3e8UXthwgKZZe73L1CFTsH5rsDQPHvWTi1aY4/jD43zzb7l8Y3ZHf8lzRFmVr6x0x5nue5ERFcoIuDnhq8kWZDa5/oEHtLmjePmuJiNCoEe0mMrVwyFewKkRrdhsqC8adqC8zGaP+6r5xhnaPesdxLzQWk1iCg3VXldemANIrddKglBk7jDO0e9OMM7R71i/6VQfvAn0qg/eBBkWbmGbBzGnb4rE1747OAiZjonf3L1TN6oJYedGnbTtWKr23ogmDE51p5JpQ6ZINR8Y4reCmtNDv8VDdjvEaXTme9x7e1So4wXihOhTPONzBzrXtUQGONsQ3um+UM9rU5b0Ecl/HAzkah6+m9W/db7XC9Yfqu++s6183FAIPLJ1VPulErOQtOkPYgklwP8AOyfrBTNYJdCT9VvyUMmBxrEk+2ra+1TN4JdCU9VvyQSVXE8xA9VvyKzxI9AfzcsD3E8xA9UfIrPEj0B/NyCoIiICIiAiIgIiICIiAiIgIiIPjtD4K1razhRB2q6XaHwVs2w2sJ5OhBQak4msJgzHge9RO48QTwc5kAeVoM1LriRL7UGYyHROiivx1s4vhznJJFHbkEIeMzXNmJo00c7TTetIbVnOBm3ZkUdl78lv7jbZsQRJs7J1duUdV7WPgTUUmoo40y70GacP7yNl5mDzmjhWp8FJZg9f9kBsqDGGjdXKFOwrffJzLDtFuy/tW22HuI75XgOfIpTfog/Q7h9inChQYA4yMgOutnbIxdgths8pAFADy1AndHGR0GHDHGjSg69FnCzccy1jfKzoMy/X80E0TcYYOyPKh8S5fXDB/FD4lD23HZ2yPK93pL79e7vxf+37oJgxjDBJA40M/wC5VGXxdguNeNAivpqGwY7OqPLN/pfuq1IY5lzwDNnM58tBNHZ+KMKKWjjANf7q1WSrHv5Dj7FIwP8AlVQ13bxkMZ0MCaNcustnbl4mOmHQaxyakdeqCU2yLxtjhh2wT21WQ5CfbEDeVWo960quXe7jLYR4StQN+q2Xu7ahjNhkGooN6DMUGIHAZ6jevSqNJRdto7xSqrINQD2iqAiIgIiICIiAiIgIiIC+EgCpX1dcU0b+aDwTMcMBNfzVoWlarYIdyslU7UmTDY7UU71hK9NuGA2JyqUBGqD22ze1kAPrEA13rFVr4iwoBdz4yr1lhy+1+TLcNzxAFetnvWpN8MVjLujDjNKV6yDdqdxXhQ3HykD/ADVvxsX4TSfKh29Oqi+tzGswnv8AKzkT1qKwJnHVwLvLDr6aCXj64YP4ofEn1wwfxQ+JQ+fXu78X/t+6fXu78X/t+6CXyYxhg7BPGhp6SxrefFuE6DE8pFaEZvB3KMaPjs7ZPleop01Y9uY3mJDdSaPcNugKDZ3FLEyFGhTFJgGoPXr2qLzF6+rJiJM86DXa62S99+sW3TEOMOMkk161VpJfy/L5t8YcKTUnegtm8ltCPNPIfU7farguRGMSbhGteUK+9YKi2i+ama1Jq73rPGG8q+NMwDQ5ub4IJO8CYZ4STNKZt3qZ3BOGRClBl0W667lENgPZkTakzs0zadFMtgxJubClcjkGitUEhFxm0gQa60CzrI9AfzcsK3KhbMGDUU5I0KzXJghra9lfmg96IiAiIgIiICIiAiIgIiICIiAcwR2qhWlD2obu8KuqnTsPaa7/APKINbL+yJiQY1BWoPfVRu4z2A6LDmuQTVrs6KVi9dncNDicmp2T4LSjE+6vGIczzdag7gg/P7jbdF73TdIR1d1e1Rh4hXVjQ48c8G7pHKma/QXi7h06MZkiBWtT0VGziPhVFdFmCJY1qT0ckETcxZsxLRzyXChrpRXdYVpTUq5g2nClFsDb+FsdkSIRLGoO5verP+r+agvygOyPolBVbGvdNQWsAiO03OzV+yl/JpjWjhnDTfmrBlrozcOg4JwppydVVGXanGgc27wpogvr6fzX37/zT6fzX37/AM1ZP0dnPu3+79k+js592/3fsgvll/5qvn36dpVz2Xf2bMRvPPOY36LETLuzm15t+nZ+yumyrvzgiM5D9R2oNsrmX2mXvhVjO6Q62a3iwzvVMRTL1iOzI31UdlyrCmmxIIMN1ajM1W92F9kzDXy9WuABagk3wytmJFbALnnOm/VbxXMnHPhwqk9ECp0WguF0lFYyXBBHROYW99yoLhCgih0BQbDWW8mG01rTvqrmb0QrWslpEJo7huV0s6IQckREBERAREQEREBERAXmmDRvdSi9K8szm3+d6CwLfilsOJnWg7arVy/0+6HDjUccgc1s9eFhLIhz0J0yWqWIMu5zI+ROR7kGiGKNvxYQmNl7hTaOuW9R6Yi3umIbpikVwzIOeS3uxUs+M8TNAc6nRR04kWNMufM0Y4jPdqg1nvRfqabEi0iuNCTk7JYnnL/TYeax39LtJVzXpsCbdEiUY+lTkKrEk7d6cLjzb9SEFw/T+a+/f+afT+a+/f8AmrJ+js592/3fsn0dnPu3+79kF6Ov/NbJ59/5qgWhfibiB1IrjllQ096pRu7OEEcG/Pu/ZeWLdeccDzbqU12dEFm29eWamA7nHGvesP2pEmZuKQdo1PbVZ6mLmTcUnmXd3JqumXw4mY0QVgOOYObSgwlYdhzExHYdgmp7FuXhTc+KY0sTCJzFTs5L5dHCqM6LCJljqD0FvLhbhc9j5cmXIIIz2UGwuB11XwxKHgvRrlkpbcJbHdCgy3IOQbu0WpGEdwzLiWJgkU2erTsUjeHt3+AhwBsUoBuQbDXUltiDC8B7VlaWbRorqArLsGV4KEwUpRunar6gto38vBB2oiICIiAiIgIiICIiAiIgIiIC6Yzdpp8KLuXwioI7UFkWxJCKxwpmR2LAN77stmWRebBqN4yW0c1ADwRQe5WTatkCMH1aM67kEZl/sOGzQjUlxnXqLSy++DfDvjHitQSeopqbeudDmA+sJprvosJ29hnCmNvycGteogglvDgWXPiESZ1+7qsZzeBDw40kzr93SinMtTB+DEc7yQZ/2BWXM4KwnEnijdajm0EKhwNiN/8ATPsZmvn1HxfwbvgUzLsEoYyMo2h05vVdZwSg0ylG19RBDScEItfshHizNfPqQi/hf9FMp9STPwjfgCfUkz8I34AghtZgjF2h5Lrl0FcFnYKRWvaeKuGY6ilzGCTARWUbSv3YVSlsFYbS08VA8IaCN+62EMSC+GTLEAEdRbbXCw4fLmDzBFCK8lbQWThFDhOZSVAofQWYLv4dMlyw8ABTds0QWzcO6rpdsCsMigG7JbaXWs0wWQqtpkBpRUOwLrNl9jmwKDs0WXbKs0QWso0ZDsQXHZ0LZa3LT3FV5ooB4LxS8KgFMsqL3ICIiAiIgIiICIiAiIgLpjNq32aruXFwqMvFBY9sy+2x4odD3rXu+VimMyLRlRQkZLaKdl9tpFK19yx3bVitjB4LAcqZhBGxiBcp8xw3NE1rQbK0pvvhe+O6N5OTUk12VMreG5bJjhOaBrXPZqsHW7hg2OYnk4Nf7EEINv4NxYj4nkrjnWmwe1Y4msE4pcfJDqT0FNnaODkOIXeSjs6Faq2Y2CcMk+SNz05sdqCGL6kIv4X/AET6kIv4X/RTKfUkz8I34An1JM/CN+AIIbBgfFP/AKZPgxffqPi/g3fApkxgkyuco2ncwVXMYJQRTyRtf/mghtZgXEJ+x+5mquOzcCHB7TxM6083opdoeCUOoJlG50/p6qvSWDEFpFZRp0/phBGpdXA8w3wzxSmmZYtt7hYSCWdBrK0pTPYyW21jYSwoRYeKigNRyKlZksDDyFLmGeAAAO9tAgx7cS4rZVsHmQKUz2cltfdixBLshgMFABoFxsO7MOAGUhtHdTRZQs6zxBAGyAABuQVGz4Gw1uWVOzJV5ooAF54EMNAy0XpQEREBERAREQEREBERAREQEREBERBwcwOr2/NeGNLB4oRr2qoogtOZspkStWd+YVuTV24cXarDB1rlmsmGG0/yoXUZdprkM9+9BhmYufBeTzQzr1VTIlx4BJHAt7ej3LOhlG6AChC4cRZ2fJBgU3Dgk+ZHwgLibiQBrBHuWfOIs7PkvhkYe9tf8aoMBG4sDdBHwr59BYP3I+H91n3iML0P9U4jC9D/AFQYDFxYG+CPhXfDuNBFDwLabuSs68Rheh/quQkWbm09lEGG5e50FhB4IfCrglbtw4QHNgexZGbJtb1R+S7GyzRuHgUFsytlMhU5NKHs8FXYEqGAUGg3DNe8Qmj9slzAA0CDixuyO/5LmiICIiAiIgIiICIiAiIgIiIOiJDDtBl3Z0VKmJJsStRup4quLiWg93ggsSbsSHErVg93crbmrqwom1WENNaLLboLTuB8V1GVb6IJO9Bg2NcqC4+Zbnn0V4n3FgV80O7krPXEmdnyXwyMPe2v+NUGAfoLB+5Hwp9BYP3I+H91n3iML0P9U4jC9D/VBgQXFgb4Q+FchcOCcxBHuWeeIwvQ/wBVyEizc2nsogwO24kEawR8IXthXKgtz4FuR9FZr4izs+S+iSaDWnyQYrlbpwWU5od3JorilbBhw6cgdmivYSrRQ0FV2tgtG4DwQUSWs9kMCjaeyiq8OAG0yoF6A1o0C5IPgAAoF9REBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREH//Z"; // Wstaw tutaj swój zakodowany obraz

// Dekodowanie Base64 na Uint8List
Uint8List imageData = base64.decode(base64Image.split(',').last);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strona Logowania',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.white,
        buttonTheme: ButtonThemeData(buttonColor: Colors.black),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
  
}


class LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _usernameError;
  String? _passwordError;
  bool isLoading = false;
  bool _rememberMe = false; // Zmienna do zapamiętania opcji "Zapamiętaj mnie"

  @override
void initState() {
  super.initState();
  _loadCredentials().then((credentials) {
    if (credentials != null) {
      // Jeśli dane zostały załadowane z pliku, ustaw je w polach
      _usernameController.text = credentials['username']!;
      _passwordController.text = credentials['password']!;
    }
    // Jeśli credentials są null, pola pozostaną puste
  });
}


  Future<void> _login(BuildContext context) async {
  setState(() {
    _usernameError = null;
    _passwordError = null;
    isLoading = true;
  });

  if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
    setState(() {
      if (_usernameController.text.isEmpty) {
        _usernameError = 'Proszę podać nazwę użytkownika';
      }
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Proszę podać hasło';
      }
      isLoading = false;
    });
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://localhost:8080/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text,
        'password': _passwordController.text,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      String role = data['role'];

      // Jeśli "Zapamiętaj mnie" jest włączone, zapisz dane logowania
      if (_rememberMe) {
        _saveCredentials(_usernameController.text, _passwordController.text);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHomePage(username: _usernameController.text),
            ),
          );
        } else if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserHomePage(username: _usernameController.text),
            ),
          );
        } else {
          _showErrorDialog(
            context,
            'Błąd logowania',
            'Nieznana rola użytkownika.',
          );
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showErrorDialog(
          context,
          'Błąd logowania',
          'Niepoprawna nazwa użytkownika lub hasło.',
        );
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _showErrorDialog(
        context,
        'Błąd połączenia',
        'Wystąpił problem z połączeniem z serwerem.',
      );
    });
  }
}

  Future<void> _saveCredentials(String username, String password) async {
  // Użycie bieżącego katalogu (obok pliku .exe)
  final directory = Directory.current; // Ścieżka do katalogu roboczego aplikacji
  final file = File('${directory.path}/credentials.json'); // Tworzenie pliku w bieżącym katalogu

  // Przygotowanie danych w formacie JSON
  Map<String, String> credentials = {
    'username': username,
    'password': password,
  };

  // Zapisanie danych w pliku JSON
  await file.writeAsString(jsonEncode(credentials));
}


Future<Map<String, String>?> _loadCredentials() async {
  try {
    final directory = Directory.current; // Katalog roboczy aplikacji
    final file = File('${directory.path}/credentials.json'); // Ścieżka do pliku

    // Jeśli plik istnieje, odczytaj dane
    if (await file.exists()) {
      final contents = await file.readAsString();
      Map<String, dynamic> credentials = jsonDecode(contents);

      // Jeśli plik zawiera dane
      if (credentials.containsKey('username') && credentials.containsKey('password')) {
        return {
          'username': credentials['username'],
          'password': credentials['password'],
        };
      }
    }
  } catch (e) {
    print('Error loading credentials: $e');
  }
  // Jeśli plik nie istnieje lub wystąpił błąd, zwróć null, aby pozostawić pola puste
  return null;
}




  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: TextStyle(color: Colors.black),
            ),
            content: Text(
              message,
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('HelpDesk Drzewniak'),
      backgroundColor: Color.fromRGBO(245, 245, 245, 1),
      elevation: 0,
      automaticallyImplyLeading: false,
    ),
    body: Stack(
      children: [
        Container(
          color: Color.fromRGBO(245, 245, 245, 1),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Image.memory(
              imageData,
              width: MediaQuery.of(context).size.width * 0.60,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Zaloguj się',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 30), // Zmniejszony odstęp między napisem a polami

                    // Pierwsze pole tekstowe
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Nazwa użytkownika',
                      icon: Icons.person,
                      errorText: _usernameError,
                    ),
                    SizedBox(height: 20),

                    // Drugie pole tekstowe
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Hasło',
                      obscureText: true,
                      icon: Icons.lock,
                      onFieldSubmitted: (_) => _login(context),
                      errorText: _passwordError,
                    ),
                    SizedBox(height: 20),

                    // Wyrównanie checkboxa z innymi polami tekstowymi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Wyrównanie na lewo
                      children: [
                        SizedBox(width: 75), // Przesunięcie checkboxa o 50 px w prawo
                        Transform.scale(
                          scale: 1.4, // Zwiększenie rozmiaru checkboxa
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value!;
                              });
                            },
                            activeColor: Color(0xFFF49402), // Kolor zaznaczonego checkboxa
                          ),
                        ),
                        Text('Zapamiętaj mnie'),
                      ],
                    ),

                    // Przycisk logowania lub animacja ładowania
                    isLoading
                        ? CircularProgressIndicator() // Animacja ładowania
                        : _buildLoginButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    required IconData icon,
    String? errorText,
    Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 450, // Szerokość kontenera
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // Zmniejszony cień
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1, // Mniejszy spread
                blurRadius: 4,   // Mniejszy blur
                offset: Offset(0, 2), // Mniejszy offset
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1, // Mniejszy spread
                blurRadius: 6,   // Mniejszy blur
                offset: Offset(0, 2), // Mniejszy offset
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.black),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              prefixIcon: Icon(icon, color: Colors.black),
            ),
            style: TextStyle(color: Colors.black),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Proszę podać $label';
              }
              return null;
            },
            onFieldSubmitted: onFieldSubmitted,
          ),
        ),
        SizedBox(height: 6), // Odstęp od pola tekstowego

        // Animowana wysokość kontenera dla błędu
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: errorText != null ? 20 : 0, // Jeśli błąd istnieje, kontener ma wysokość 20
          curve: Curves.easeInOut,
          child: errorText != null
              ? Text(
            errorText,
            style: TextStyle(color: Colors.red, fontSize: 12),
          )
              : SizedBox.shrink(), // Jeśli brak błędu, wyświetla pusty widget
        ),
      ],
    );
  }
  

  Widget _buildLoginButton(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: () => _login(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          minimumSize: Size(200, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: Text(
          'Zaloguj się',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

