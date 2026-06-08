#ifndef BALANCESOLVER_H
#define BALANCESOLVER_H

#pragma once

#include <QString>
#include <QVector>

#include "TransportProblemState.h"

struct BalanceResult
{
    bool valid = false;
    bool alreadyBalanced = false;

    int sumSupply = 0;
    int sumDemand = 0;

    QString message;

    QVector<QVector<int>> costMatrix;
    QVector<int> supply;
    QVector<int> demand;
};

class BalanceSolver
{
public:
    BalanceResult solve(const TransportProblemState& source) const;
};

#endif // BALANCESOLVER_H
